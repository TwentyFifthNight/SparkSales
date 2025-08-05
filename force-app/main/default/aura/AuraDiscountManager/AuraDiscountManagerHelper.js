({
    loadData : function(component) {
        const action = component.get("c.getRecordCount");
        component.set("v.isLoading", true);

        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const count = response.getReturnValue();
                component.set("v.allRecordsCount", count);
                const perPage = component.get("v.recordsPerPage");
                component.set("v.totalPages", Math.ceil(count / perPage));
                this.loadRecords(component, 1);
            } else {
                component.set("v.error", response.getError()[0].message);
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },

    loadRecords : function(component, pageNumber) {
        const action = component.get("c.getRecordList");
        const recordsPerPage = component.get("v.recordsPerPage");
        const offset = (pageNumber - 1) * recordsPerPage;

        component.set("v.isLoading", true);

        action.setParams({ recordsPerPage: recordsPerPage, offset: offset });

        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const data = [];
                let rawData = response.getReturnValue();
                for (var i = 0; i < rawData.length; i++) {
                    var row = rawData[i];
                    data.push({
                        Id: row.Id,
                        Name: row.Name,
                        recordLink: '/' + row.Id,
                        productLink: '/' + row.Product__c,
                        pricebookLink: '/' + row.Pricebook__c,
                        productName: row.Product__r ? row.Product__r.Name : '',
                        pricebookName: row.Pricebook__r ? row.Pricebook__r.Name : '',
                        active: row.isActive__c
                    });
                }
                component.set("v.discounts", data);
                component.set("v.error", null);
                component.set("v.currentPage", pageNumber);
            } else {
                component.set("v.error", response.getError()[0].message);
                component.set("v.discounts", []);
            }
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(action);
    }
})