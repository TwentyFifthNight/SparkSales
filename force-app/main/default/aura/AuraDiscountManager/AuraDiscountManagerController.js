({
    init : function(component, event, helper) {
        component.set("v.columns", [
            { label: "Name", fieldName: "recordLink", type: "url", typeAttributes: { label: { fieldName: "Name" }, target: "_blank" } },
            { label: "Product", fieldName: "productLink", type: "url", typeAttributes: { label: { fieldName: "productName" }, target: "_blank" } },
            { label: "Pricebook", fieldName: "pricebookLink", type: "url", typeAttributes: { label: { fieldName: "pricebookName" }, target: "_blank" } },
            { label: "Active", fieldName: "active", type: "boolean" }
        ]);
        component.set("v.pageSizeOptions", [
            { label: "5", value: "5" },
            { label: "10", value: "10" },
            { label: "15", value: "15" },
            { label: "20", value: "20" }
        ]);
        helper.loadData(component);
    },

    handlePageSizeChange : function(component, event, helper) {
        let value = event.getSource().get("v.value");
        component.set("v.recordsPerPage", parseInt(value));
        component.set("v.recordsPerPageString", value);
        component.set("v.currentPage", 1);
        helper.loadRecords(component, 1);
    },

    handleFirstPageClick : function(component, event, helper) {
        helper.loadRecords(component, 1);
    },

    handlePreviousPageClick : function(component, event, helper) {
        let currentPage = component.get("v.currentPage");
        if (currentPage > 1) {
            helper.loadRecords(component, currentPage - 1);
        }
    },

    handleNextPageClick : function(component, event, helper) {
        let currentPage = component.get("v.currentPage");
        let totalPages = component.get("v.totalPages");
        if (currentPage < totalPages) {
            helper.loadRecords(component, currentPage + 1);
        }
    },

    handleLastPageClick : function(component, event, helper) {
        helper.loadRecords(component, component.get("v.totalPages"));
    },

    openModal : function(component) {
        component.set("v.isModalOpen", true);
        setTimeout(function() {
            const flow = component.find("discountFlow");
            if (flow) {
                flow.startFlow("Create_New_Discount");
            }
        }, 0);
    },

    closeModal : function(component) {
        component.set("v.isModalOpen", false);
    },

    handleFlowStatusChange : function(component, event, helper) {
        if (event.getParam("status") === "FINISHED") {
            component.set("v.isModalOpen", false);
            helper.loadData(component);
        }
    }
})