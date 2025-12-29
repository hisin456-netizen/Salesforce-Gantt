import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import DHTMLX_GANTT from '@salesforce/resourceUrl/dhtmlxGantt_v2';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLastProjectId from '@salesforce/apex/GanttDataService.getLastProjectId';
import getProjects from '@salesforce/apex/GanttDataService.getProjects';
import getGanttData from '@salesforce/apex/GanttDataService.getGanttData';
import saveTask from '@salesforce/apex/GanttDataService.saveTask';
import updateTask from '@salesforce/apex/GanttDataService.updateTask';
import saveLink from '@salesforce/apex/GanttDataService.saveLink';
import deleteTask from '@salesforce/apex/GanttDataService.deleteTask';
import deleteLink from '@salesforce/apex/GanttDataService.deleteLink';
import reorderTask from '@salesforce/apex/GanttDataService.reorderTask';

export default class GanttChart extends LightningElement {
    @api recordId; 
    
    // Project Selection
    projectOptions = [];
    selectedProjectId = '';
    selectedProjectName = ''; // Display Name
    isProjectSelected = false;

    isGanttInitialized = false;

    connectedCallback() {
        // If loaded on a Record Page, recordId is automatic
        if (this.recordId) {
            this.selectedProjectId = this.recordId;
            this.isProjectSelected = true;
        } else {
            // If loaded on App Page (no recordId), fetch list
            this.loadProjectList();
        }
    }

    loadProjectList() {
        getProjects()
            .then(result => {
                this.projectOptions = result.map(proj => {
                    return { label: proj.Name, value: proj.Id };
                });
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load projects: ' + error.body?.message, 'error');
            });
    }

    handleProjectChange(event) {
        this.selectedProjectId = event.detail.value;
        this.recordId = this.selectedProjectId; // Sync recordId
        this.isProjectSelected = true;
        
        // Trigger Gantt load if not already initialized or needs reload
        // Since we used lwc:dom="manual", the container might need re-init if it was removed from DOM.
        // With if:true, the DOM is fresh. We need to wait for render.
    }

    renderedCallback() {
        // Only initialize if project is selected and container exists
        if (!this.isProjectSelected || this.isGanttInitialized) {
            return;
        }

        // We need to wait for the div to be in the DOM after isProjectSelected becomes true
        // The condition above (!this.isProjectSelected) handles the case where it's false.
        // But if it JUST became true, querySelector might still be null in this cycle if not carefully timed.
        // Usually renderedCallback runs after the template update.
        
        const root = this.template.querySelector('.gantt-container');
        if(!root) return; // Guard clause

        this.isGanttInitialized = true;

        Promise.all([
            loadScript(this, DHTMLX_GANTT + '/dhtmlxgantt.js'),
            loadStyle(this, DHTMLX_GANTT + '/dhtmlxgantt.css')
        ])
            .then(() => {
                this.initializeGantt();
            })
            .catch(error => {
                this.showToast('Error loading DHTMLX Gantt', error.message, 'error');
            });
    }

    initializeGantt() {
        const root = this.template.querySelector('.gantt-container');
        
        // --- 1. Configuration ---
        window.gantt.config.date_format = "%Y-%m-%d"; 
        window.gantt.config.order_branch = true; 
        
        // Columns: Standard Setup (No Resources)
        window.gantt.config.columns = [
            { name: "text", label: "Task Name", tree: true, width: 250 },
            { name: "start_date", label: "Start Time", align: "center" },
            { name: "duration", label: "Duration", align: "center" },
            { name: "add", label: "", width: 44 }
        ];

        // Lightbox: Standard Setup (No Resources)
        window.gantt.config.lightbox.sections = [
            {name: "description", height: 38, map_to: "text", type: "textarea", focus: true},
            {name: "desc_detail", height: 70, map_to: "description", type: "textarea"}, 
            {name: "priority", height: 22, map_to: "priority", type: "select", options: [
                {key: 1, label: "High"},
                {key: 2, label: "Normal"},
                {key: 3, label: "Low"}
            ]}, 
            {name: "time", height: 72, type: "duration", map_to: "auto"}
        ];

        window.gantt.locale.labels.section_description = "Task Name";
        window.gantt.locale.labels.section_desc_detail = "Description";
        window.gantt.locale.labels.section_priority = "Priority";
        window.gantt.locale.labels.section_time = "Time Period";
        
        // --- 2. Initialization ---
        window.gantt.init(root);
        
        // --- 3. Event Handlers ---
        
        // Row Reordering
        window.gantt.attachEvent("onAfterTaskMove", (id, parent, tindex) => {
            console.log(`🔄 Reordering Task ${id} to Parent ${parent} at Index ${tindex}`);
            reorderTask({ taskId: id, parentId: parent, index: tindex })
            .then(() => console.log('✅ Task Reordered'))
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to reorder task: ' + error.body.message,
                        variant: 'error'
                    })
                );
            });
        });

        // Task Add
        window.gantt.attachEvent("onAfterTaskAdd", (id, task) => {
            const taskData = {
                ...task,
                parent_project_id: this.recordId,
                start_date: window.gantt.date.date_to_str("%Y-%m-%d")(task.start_date)
            };
            saveTask({ taskData: JSON.stringify(taskData) })
                .then(newId => window.gantt.changeTaskId(id, newId))
                .catch(error => console.error(error));
        });

        // Task Update
        window.gantt.attachEvent("onAfterTaskUpdate", (id, task) => {
            const taskData = {
                ...task,
                start_date: window.gantt.date.date_to_str("%Y-%m-%d")(task.start_date)
            };
            updateTask({ taskData: JSON.stringify(taskData) })
                .catch(error => console.error(error));
        });

        // Link Add
        window.gantt.attachEvent("onAfterLinkAdd", (id, link) => {
            const linkData = { ...link, parent_project_id: this.recordId };
            saveLink({ linkData: JSON.stringify(linkData) })
                .then(newId => window.gantt.changeLinkId(id, newId))
                .catch(error => console.error(error));
        });

        // Delete Handlers
        window.gantt.attachEvent("onAfterTaskDelete", (id) => deleteTask({ taskId: id }));
        window.gantt.attachEvent("onAfterLinkDelete", (id) => deleteLink({ linkId: id }));

        // Load Data from Apex
        this.loadTasks();
    }

    loadTasks() {
        console.log('🚀 loadTasks called. RecordId:', this.recordId);

        if (!this.recordId) {
            return; // Should not happen if flow is correct
        }

        // Standard Load without Resources
        getGanttData({ projectId: this.recordId })
            .then(result => {
                console.log('✅ Gantt Data Loaded:', result);
                
                if (result && result.projectName) {
                    this.selectedProjectName = result.projectName;
                }

                if (!result || !result.data || result.data.length === 0) {
                    console.warn('⚠️ No tasks found for this project.');
                }
                window.gantt.clearAll();
                window.gantt.parse(result);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Gantt Data',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
