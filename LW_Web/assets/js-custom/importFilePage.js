

$(function () {

    $('#btnUpload').on('click', function () {
        var e = document.getElementById("SelectedFile");

        var x = setInterval(function () {
            $.ajax({
                type: "POST",
                url: "/Import/Counter/" + e.value,
                dataType: "json",
                success: function (result, status, xhr) {
                    $("#counterMsg").html("Progress: " + result["Count"] + (result["Message"] == null ? "" : " " + result["Message"]));
                },
                error: function (xhr, exception) { alert(exception); }
            });

            return false;
        }, 4000);

        $("#counterMsg").html("Progress: reading file...");

        $('#btnUpload').addClass('disabled');
    });

});
