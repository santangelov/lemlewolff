var uploadInterval; // Declare globally

$('#btnUpload').on('click', function () {
    var e = document.getElementById("SelectedFile");

    // Clear existing interval if any
    if (uploadInterval) {
        clearInterval(uploadInterval);
    }

    uploadInterval = setInterval(function () {
        $.ajax({
            type: "POST",
            url: "/Import/Counter/" + e.value,
            dataType: "json",
            async: true, // Ensure async (should be by default)
            success: function (result, status, xhr) {
                $("#counterMsg").html("Progress: " + result["Count"] + (result["Message"] == null ? "" : " " + result["Message"]));

                // Stop when done
                if (result["Message"] === "Completed") {
                    clearInterval(uploadInterval);
                    uploadInterval = null; // Reset
                    $('#btnUpload').removeClass('disabled');
                }
            },
            error: function (xhr, exception) { alert(exception); }
        });

    }, 4000); // Fires every 4 seconds

    $("#counterMsg").html("Progress: reading file...");
    $('#btnUpload').addClass('disabled');
});
