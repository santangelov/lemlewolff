var isPolling = false; // Global flag to prevent duplicate polling

$('#btnUpload').on('click', function () {
    var fileType = document.getElementById("SelectedFile").value;

    if (!fileType) {
        alert("Please select a valid file type.");
        return;
    }

    if (isPolling) {
        console.log("Already polling. Ignoring duplicate click.");
        return;
    }

    $("#counterMsg").html("Progress: reading file...");
    $('#btnUpload').addClass('disabled');
    isPolling = true;

    pollUploadStatus(fileType); // Start polling loop
});

function pollUploadStatus(fileType) {
    $.ajax({
        type: "POST",
        url: "/Import/Counter/" + fileType,
        dataType: "json",
        async: true,
        success: function (result) {
            try {
                if (typeof result !== "object" || result === null) {
                    throw new Error("Invalid JSON object received");
                }

                const count = result["Count"];
                const msg = result["Message"];

                if (count !== undefined || msg) {
                    $("#counterMsg").html("Progress: " + count + (msg ? " " + msg : ""));
                } else {
                    $("#counterMsg").html("Waiting for response...");
                }

                if (msg === "Completed") {
                    isPolling = false;
                    $('#btnUpload').removeClass('disabled');
                    console.log("Polling completed.");
                } else {
                    setTimeout(() => pollUploadStatus(fileType), 4000);
                }
            } catch (ex) {
                console.warn("Polling JSON parse error or result issue:", ex, result);
                $("#counterMsg").html("Polling error — waiting...");
                setTimeout(() => pollUploadStatus(fileType), 6000);
            }
        },
        error: function (xhr, status, error) {
            console.warn("Counter polling failed:", status, error);
            $("#counterMsg").html("Polling failed — retrying...");
            setTimeout(() => pollUploadStatus(fileType), 8000);
        }
    });
}
