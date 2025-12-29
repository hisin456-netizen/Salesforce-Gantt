import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import DHTMLX_GANTT from '@salesforce/resourceUrl/dhtmlxGantt_v2';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLastProjectId from '@salesforce/apex/GanttDataService.getLastProjectId';
import getGanttData from '@salesforce/apex/GanttDataService.getGanttData';
import saveTask from '@salesforce/apex/GanttDataService.saveTask';
import updateTask from '@salesforce/apex/GanttDataService.updateTask';
import saveLink from '@salesforce/apex/GanttDataService.saveLink';
import deleteTask from '@salesforce/apex/GanttDataService.deleteTask';
import deleteLink from '@salesforce/apex/GanttDataService.deleteLink';
import reorderTask from '@salesforce/apex/GanttDataService.reorderTask';

export default class GanttChart extends LightningElement {
    @api recordId; 
    isGanttInitialized = false;

    renderedCallback() {
        if (this.isGanttInitialized) {
            return;
        }
        this.isGanttInitialized = true;

        Promise.all([
            loadScript(this, DHTMLX_GANTT + '/dhtmlxgantt.js'),
            loadStyle(this, DHTMLX_GANTT + '/dhtmlxgantt.css')
        ])
            .then(() => {
                this.initializeGantt();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading DHTMLX Gantt',
                        message: error.message,
                        variant: 'error'
                    })
                );
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
            console.warn('⚠️ No RecordId found. Attempting to load most recent project...');
            getLastProjectId()
                .then(id => {
                    if (id) {
                        this.recordId = id;
                        this.loadTasks(); 
                    } else {
                        console.error('❌ No projects found.');
                    }
                })
                .catch(error => console.error(error));
            return; 
        }

        // Standard Load without Resources
        getGanttData({ projectId: this.recordId })
            .then(result => {
                console.log('✅ Gantt Data Loaded:', result);
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
}
