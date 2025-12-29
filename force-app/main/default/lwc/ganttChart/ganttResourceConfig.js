/* eslint-disable */
/**
 * ganttResourceConfig.js
 * External configuration for DHTMLX Gantt Resources
 * Exports functions to ensure window.gantt is available when called
 */

const getResourceColumn = () => {
    return { 
        name: "owner_id", 
        label: "Assigned To", 
        align: "center", 
        width: 100, 
        template: function(task) {
            if (!task || !task.owner_id) return "";
            
            const resources = window.gantt.serverList("resources");
            if (!resources || resources.length === 0) return "";
            
            const res = resources.find(r => r.key == task.owner_id);
            return res ? res.label : "";
        } 
    };
};

const getResourceLightboxSection = () => {
    return {
        name: "owner", 
        height: 22, 
        map_to: "owner_id", 
        type: "select", 
        options: window.gantt.serverList("resources")
    };
};

export { getResourceColumn, getResourceLightboxSection };
