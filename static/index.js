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
            ip: parent.parent().find(".ip").text(),
            url: parent.parent().find(".url").val(),
            rotation: parent.parent().find(".rotation").val(),
            zoom: parent.parent().find(".zoom").val(),
        },
        success: function(result){
            parent.parent().removeClass("table-warning");
            parent.find(".save").remove();
            parent.find(".cancel").remove();
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
    '<td><input class="url"/></td>'+
    '<td><select class="rotation"><option selected>0</option><option>90</option><option>180</option><option>270</option></select></td>'+
    '<td><input class="zoom" type="number"/></td>'+
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
    $(".pis").append('<tr class="table-success">'+
    '<td><input hidden class="originalmac" value=""></td>'+
    '<td><input class="mac"></td>'+
    '<td><input class="name"></td>'+
    '<td><div class="ip"></div></td>'+
    '<td><input class="url"/></td>'+
    '<td><select class="rotation"><option selected>0</option><option>90</option><option>180</option><option>270</option></select></td>'+
    '<td><input class="zoom" type="number"/></td>'+
    '<td><button class="btn btn-primary save">Save</button> <button class="btn btn-danger cancel">Cancel</button></td>'+
    '</tr>');
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