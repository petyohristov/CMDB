function form_new_environment(appl) {
   $("#"+appl+"_addEnv").slideDown();

    
}

function add_new_environment(appl) {
    
    var elevel =1
    var colsForExecution = hlevel - elevel;
    var wait = 100;

    //console.log(hlevel, " ", level, " ", colsForExecution);

    if (elevel < hlevel) {
        for (id = hlevel; id >= elevel + 1; id--) {
            $("#Level_" + id).delay(200 * (hlevel - id)).slideUp(500, function() {
                $(this).remove();
            });

            //console.log("Removed CI ", selectedCIs[id - 1]);

            $("#ID" + selectedCIs[id - 1]).delay(200 * (hlevel - id)).slideUp(500, function() {
                $(this).remove();
            });
        }
        //hlevel = level;
        selectedCIs.splice(hlevel, colsForExecution);
    }

    //$("#"+appl).find("#Level_2").slideUp(500, function() {$(this).remove();});
    ((colsForExecution) == 0) ? wait = 0: wait = 200 * colsForExecution + 510;
    //console.log("colsForExecution=", colsForExecution, " wait=", wait);
    setTimeout(function() {
        GetChildrenOfCI(appl,"3",2);
    }, wait);

    return true;
}

function setEnvName(selected) {
    var envID = $(selected).find(":selected").text();

    $("#name_of_env").val(envID);
    return true;
}
