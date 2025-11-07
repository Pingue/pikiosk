$(function() {
});

$(document).on('click', '.edit', function(){ 
    $(this).parent().parent().find("input,select").each(function(){
        $(this).attr("orig", $(this).val());
    });
    $(this).parent().parent().find("input,select").removeAttr("disabled");
    $(this).parent().parent().addClass("table-success");
    parent = $(this).parent();
    $(this).remove();
    parent.find(".delete").remove();
    parent.append("<button class='btn btn-primary save'>Save</button> <button class='btn btn-danger cancel'>Cancel</button>");
}); 

$(document).on('click', '.save', function(){ 
    console.log($(this));
    ip = $(this).parent().parent().find(".ip")
    if(ip.text() == ""){
        ip.text("New");
    }
    $(this).parent().parent().find("input,select").attr("disabled", "true");
    $(this).parent().parent().removeClass("table-success");
    $(this).parent().parent().addClass("table-warning");
    parent = $(this).parent();
    $.ajax({
        url: "update", 
        type: "GET",
        data: {
            originalmac: parent.parent().find(".originalmac").val(),
            mac: parent.parent().find(".mac").val(),
            name: parent.parent().find(".name").val(),
//            ip: parent.parent().find(".ip").text(),
            url: parent.parent().find(".url").val(),
            rotation: parent.parent().find(".rotation").val(),
            zoom: parent.parent().find(".zoom").val(),
        },
        success: function(result){
            parent.parent().removeClass("table-warning");
            parent.find(".save").remove();
            parent.find(".cancel").remove();
            parent.prev().html('<button type="button" class="btn btn-primary refresh">Refresh</button> <button type="button" class="btn btn-warning reload">Reload</button> <button type="button" class="btn btn-danger reboot">Reboot</button>')
            parent.append('<button type="button" class="btn btn-success edit">Edit</button> <button type="button" class="btn btn-danger delete">Delete</button>');
        },
        error: function(result){
            ip.text("");
        }
    });
}); 

$(document).on('click', '.cancel', function(){ 
    if($(this).parent().parent().find(".ip").text( ) == ""){
        mac = $(this).parent().parent().find(".mac").val();
        $(this).parent().parent().remove();
        if(mac == "" || mac == undefined){
            return
        }
        $(".macs").append('<tr><td class="mac">'+mac+'</td><td><button type="button" class="btn btn-success configure">Configure</button> <button type="button" class="btn btn-danger forget">Forget</button></td></tr>');
        return
    }
    $(this).parent().parent().find("input,select").each(function(){
        $(this).val($(this).attr("orig"));
    });

    $(this).parent().parent().find("input,select").attr("disabled", "true");
    $(this).parent().parent().removeClass("table-success");
    parent = $(this).parent();
    $(this).remove();
    parent.find(".save").remove();
    parent.append('<button type="button" class="btn btn-success edit">Edit</button> <button type="button" class="btn btn-danger delete">Delete</button>');
}); 

$(document).on('click', '.configure', function(){ 
    mac = $(this).parent().parent().find(".mac").text();
    $(this).parent().parent().remove();
    $(".pis").append('<tr class="table-success">'+
    '<td><input hidden class="originalmac" value="'+mac+'"></td>'+
    '<td><input class="mac" value="'+mac+'"></td>'+
    '<td><input class="name"></td>'+
    '<td><div class="ip"></div></td>'+
    '<td><div class="time"></div></td>'+
    '<td><input class="url"/></td>'+
    '<td><select class="rotation"><option selected>0</option><option>90</option><option>180</option><option>270</option></select></td>'+
    '<td><input class="zoom" type="number"/></td>'+
    '<td><button type="button" class="btn btn-primary refresh">Refresh</button> <button type="button" class="btn btn-warning reload">Reload</button> <button type="button" class="btn btn-danger reboot">Reboot</button></td>'+
    '<td><button class="btn btn-primary save">Save</button> <button class="btn btn-danger cancel">Cancel</button></td>'+
    '</tr>');
}); 

$(document).on('click', '.delete', function(){

    mac = $(this).parent().parent().find(".mac").val();
    parent = $(this).parent();
    parent.parent().addClass("table-warning");
    $.ajax({
        url: "delete",
        type: "GET",
        data: {
            mac: mac,
        },
        success: function(result){
            parent.parent().remove();
            $(".macs").append('<tr><td class="mac">'+mac+'</td><td><button type="button" class="btn btn-success configure">Configure</button> <button type="button" class="btn btn-danger forget">Forget</button></td></tr>');
        },
        error: function(result){
            parent.parent().remove();
            $(".macs").append('<tr><td class="mac">'+mac+'</td><td><button type="button" class="btn btn-success configure">Configure</button> <button type="button" class="btn btn-danger forget">Forget</button></td></tr>');
        }
    })
});

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

$(document).on('click', '.forget', function(){
    parent = $(this).parent();
    parent.parent().addClass("table-warning");
    $.ajax({
        url: "forget",
        type: "GET",
        data: {
            mac: $(this).parent().parent().find(".mac").text(),
        },
        success: function(result){
            parent.parent().remove();
        }
    })
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