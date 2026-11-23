function escapeHtml(value) {
    if (value === null || value === undefined) {
        return "";
    }
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function safeHref(url) {
    return /^https?:\/\//i.test(url || "") ? escapeHtml(url) : "#";
}

$(document).on('click', '.add', function(){
    // Clear the form and show the modal
    $('#addForm')[0].reset();
    $('#addModal').modal('show');
});

$(document).on('click', '#saveAdd', function(){
    var table = $('#testtable').DataTable();
    
    // Get form data
    var formData = {
        mac: $('#addMac').val().trim(),
        name: $('#addName').val().trim(),
        url: $('#addUrl').val().trim(),
        rotation: $('#addRotation').val(),
        zoom: $('#addZoom').val()
    };
    
    // Validate required fields
    if (!formData.mac || !formData.name || !formData.url) {
        alert("Please fill in all required fields");
        return;
    }
    
    // Validate MAC address format (basic validation)
    var macPattern = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/;
    if (!macPattern.test(formData.mac)) {
        alert("Please enter a valid MAC address (XX:XX:XX:XX:XX:XX)");
        return;
    }
    
    // Disable the save button to prevent double submission
    $('#saveAdd').prop('disabled', true).text('Adding...');
    
    // Add via AJAX
    $.ajax({
        url: "update",
        type: "GET",
        data: formData,
        success: function(result){
            // Hide the modal
            $('#addModal').modal('hide');
            // Reload the DataTable
            table.ajax.reload();
            console.log("Pi added successfully");
            // Show success message
            alert("Pi added successfully!");
        },
        error: function(result){
            var errorMsg = "Error adding Pi";
            try {
                var response = JSON.parse(result.responseText);
                if (response.error) {
                    errorMsg += ": " + response.error;
                }
            } catch(e) {
                errorMsg += ": " + result.responseText;
            }
            alert(errorMsg);
        },
        complete: function() {
            // Re-enable the save button
            $('#saveAdd').prop('disabled', false).text('Add Pi');
        }
    });
});

$(document).on('click', '.refresh', function(){ 
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();
    var mac = data.mac;
    
    $.ajax({
        url: "refresh",
        type: "GET",
        data: {
            mac: mac,
        },
        success: function(result){
            console.log("Refreshed");
        },
        error: function(result){
            console.log("Error refreshing");
        }
    });
});


$(document).on('click', '.reload', function(){ 
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();
    var mac = data.mac;
    
    $.ajax({
        url: "reload",
        type: "GET",
        data: {
            mac: mac,
        },
        success: function(result){
            console.log("Reloaded");
        },
        error: function(result){
            console.log("Error reloading");
        }
    });
});


$(document).on('click', '.reboot', function(){ 
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();
    var mac = data.mac;
    
    $.ajax({
        url: "reboot",
        type: "GET",
        data: {
            mac: mac,
        },
        success: function(result){
            console.log("Rebooted");
        },
        error: function(result){
            console.log("Error rebooting");
        }
    });
});


$(document).on('click', '.gitpull', function(){ 
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();
    var mac = data.mac;
    
    $.ajax({
        url: "gitpull",
        type: "GET",
        data: {
            mac: mac,
        },
        success: function(result){
            console.log("Updating");
        },
        error: function(result){
            console.log("Error updating");
        }
    });
});

$(document).on('click', '.configure-pi', function(){
    var table = $('#testtable').DataTable();
    var data = table.row($(this).closest('tr')).data();

    if (!confirm("Run configure (ansible) on " + (data.name || data.mac) + "? This takes several minutes.")) {
        return;
    }

    $.ajax({
        url: "configure",
        type: "GET",
        data: {
            mac: data.mac,
        },
        success: function(result){
            console.log("Configure started");
        },
        error: function(result){
            alert("Error starting configure: " + result.responseText);
        }
    });
});

$(document).on('click', '.shutdown', function(){
    var table = $('#testtable').DataTable();
    var data = table.row($(this).closest('tr')).data();

    if (!confirm("Shut down " + (data.name || data.mac) + "? It will need to be power-cycled to come back.")) {
        return;
    }

    $.ajax({
        url: "shutdown",
        type: "GET",
        data: {
            mac: data.mac,
        },
        success: function(result){
            console.log("Shutting down");
        },
        error: function(result){
            alert("Error shutting down: " + result.responseText);
        }
    });
});

$(document).on('click', '.edit-entry', function(){
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();
    
    // Populate modal with current data
    $('#editMac').val(data.mac);
    $('#editName').val(data.name || "");
    $('#editUrl').val(data.url || "");
    $('#editRotation').val(data.rotation || "0");
    $('#editZoom').val(data.zoom || "1");
    
    // Show the modal
    $('#editModal').modal('show');
});

$(document).on('click', '#saveEdit', function(){
    var table = $('#testtable').DataTable();
    
    // Get form data
    var formData = {
        originalmac: $('#editMac').val(),
        mac: $('#editMac').val(), // Keep the same MAC
        name: $('#editName').val().trim(),
        url: $('#editUrl').val().trim(),
        rotation: $('#editRotation').val(),
        zoom: $('#editZoom').val()
    };
    
    // Validate required fields
    if (!formData.name || !formData.url) {
        alert("Please fill in all required fields");
        return;
    }
    
    // Disable the save button to prevent double submission
    $('#saveEdit').prop('disabled', true).text('Saving...');
    
    // Update via AJAX
    $.ajax({
        url: "update",
        type: "GET",
        data: formData,
        success: function(result){
            // Hide the modal
            $('#editModal').modal('hide');
            // Reload the DataTable
            table.ajax.reload();
            console.log("Pi updated successfully");
            // Show success message
            alert("Pi updated successfully!");
        },
        error: function(result){
            var errorMsg = "Error updating Pi";
            try {
                var response = JSON.parse(result.responseText);
                if (response.error) {
                    errorMsg += ": " + response.error;
                }
            } catch(e) {
                errorMsg += ": " + result.responseText;
            }
            alert(errorMsg);
        },
        complete: function() {
            // Re-enable the save button
            $('#saveEdit').prop('disabled', false).text('Save Changes');
        }
    });
});

$(document).on('click', '.delete-entry', function(){ 
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();
    
    // Confirm deletion
    if (!confirm("Are you sure you want to delete the configuration for " + (data.name || data.mac) + "?")) {
        return;
    }
    
    $.ajax({
        url: "delete",
        type: "GET",
        data: {
            mac: data.mac,
        },
        success: function(result){
            // Reload the DataTable
            table.ajax.reload();
            console.log("Pi configuration deleted successfully");
        },
        error: function(result){
            alert("Error deleting Pi: " + result.responseText);
        }
    });
});
$(document).on('click', '.forget-entry', function(){
    var table = $('#testtable').DataTable();
    var row = table.row($(this).closest('tr'));
    var data = row.data();

    if (!confirm("Forget " + (data.name || data.mac) + " entirely? It will reappear as unconfigured next time it checks in.")) {
        return;
    }

    $.ajax({
        url: "forget",
        type: "GET",
        data: {
            mac: data.mac,
        },
        success: function(result){
            table.ajax.reload();
        },
        error: function(result){
            alert("Error forgetting Pi: " + result.responseText);
        }
    });
});
