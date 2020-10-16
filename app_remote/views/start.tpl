<head>
    <meta charset="utf-8">
    <meta name="google-signin-client_id" content="574214751214-trvmfkioqrf9f85a6vmbg956tkh44i98.apps.googleusercontent.com">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/combine/npm/@zendeskgarden/css-bedrock@7.0.21,npm/@zendeskgarden/css-utilities@4.3.0">
    <link href="https://cdn.jsdelivr.net/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <br>
    <div id='app_div'>
        <div id='buttons'>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('Test');">FW to TEST</button>
            <br>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('ProductOwner');">FW to Product Owner</button>
            <br>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('CTO');">FW to CTO</button>
            <br>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('IT');">FW to IT</button>
            <br>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('Tallinja');">FW to Tallinja</button>
            <br>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('Pame');">FW to Pame</button>
            <br>
            <button id="cpt_button" class="btn btn-default btn-block" onclick="validateSend('Muving');">FW to Muving</button>
            <br>
        </div>
    </div>
    <script src="https://static.zdassets.com/zendesk_app_framework_sdk/2.0/zaf_sdk.min.js"></script>
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/emailjs-com@2.4.0/dist/email.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.5.1.min.js" integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" crossorigin="anonymous"></script>
    <script src="https://apis.google.com/js/platform.js" async defer></script>
    <script type=text/javascript>
        var client = ZAFClient.init();
        client.invoke('resize', { width: '100%', height: '380px' });

        function validateSend(destination) {
            var app_div = document.getElementById('app_div');

            var text_box = document.createElement("INPUT");
            text_box.setAttribute('id', 'text_box');
            text_box.setAttribute("type", "text");

            var buttons_div = document.getElementById('buttons');
            buttons_div.remove();

            var text_button = document.createElement("button");
            text_button.setAttribute('id', 'text_button');
            text_button.setAttribute('class', 'btn btn-default btn-block');
            text_button.innerHTML = 'Confirm Destination: '+destination;

            app_div.appendChild(text_box);
            app_div.appendChild(text_button);

            text_button.onclick = function() {
                if (text_box.value == destination) {
                    sendEmail(destination);
                }

                else {
                    app_div.innerHTML = 'No destination confirmed.'
                }
            }
        }

        function sendEmail(destination) {

            $("body").css("cursor", "progress");

            client.get(['ticket.id', 'ticket.status', 'ticket.tags','ticket.subject', 'ticket.description', 'ticket.requester', 'ticket.comments', 'ticket.customField:custom_field_360009064098', 'ticket.customField:custom_field_360009089098']).then(
                function(data) {
                    var ticket_title = data['ticket.subject'].replace(/(\r\n|\n|\r)/gm, "");
                    var ticket_id = data['ticket.id'];
                    var ticket_status = data['ticket.status'];
                    var ticket_tags = data['ticket.tags'];
                    var ticket_requester = data['ticket.requester'].email;
                    var ticket_description = data['ticket.description'].split('Reported')[0];
                    var ticket_full_description = data['ticket.description'].replace(/\n/g, "<br />")
                    var category = data['ticket.customField:custom_field_360009064098'];
                    var app = data['ticket.customField:custom_field_360009089098'];
                    var ticket_attachments = [];

                    if ((destination == 'Pame' || destination == 'Tallinja') && (destination.toLowerCase() != app)) {
                        updateApp('<b>App and Destination don\'t match</b>');
                        return;
                    }

                    for (var i = 0; i < data['ticket.comments'].length; i++) {
                        for (var x = 0; x < data['ticket.comments'][i]["imageAttachments"].length; x++) {
                            ticket_attachments.push(data['ticket.comments'][i]["imageAttachments"][x]["contentUrl"]);
                        }
                    }

                    if (data['ticket.description'].indexOf("**Non Image Attachments:**") != '-1') {
                        other_attachment = data['ticket.description'].split('mp4](')[1];
                        other_attachment = other_attachment.slice(0, -2);
                        ticket_attachments.push(other_attachment);
                    }

                    if (ticket_description.split(' ')[0] == 'Title:	') {
                        ticket_description = ticket_description.split('Title:	')[1];
                    }
                    
                    ticket_description = "<b>Requester Email: </b>" + ticket_requester + "<br /><br ><b>Previous communication as below:</b><br /><br />" + ticket_description;

                    ticket_description = ticket_description.replace(/\n/g, "<br />");

                    var data = {
                        destination: destination,
                        id: ticket_id,
                        status: ticket_status,
                        tags: ticket_tags,
                        title: ticket_title,
                        requester: ticket_requester,
                        description: ticket_description,
                        full_description: ticket_full_description,
                        category: category,
                        app: app,
                        attachments: ticket_attachments
                    }

                    if (category != null) {
                        ajaxCall(data);
                    }

                    else {
                        $("body").css("cursor", "default");
                        updateApp('<b>A Category needs to be selected before forwarding an email');
                    }
                }
            );
        }

        function ajaxCall(data) {
            $.ajax({
            method: 'GET',
            url: 'mail',
            data: data,
            success: function(response) {
                $("body").css("cursor", "default");

                if (response) {
                    updateApp(response);
                }
            }
            });
        }

        function updateApp(text) {
            var text_box = document.getElementById('text_box');
            var text_button = document.getElementById('text_button');
            text_box.remove();
            text_button.remove();

            document.getElementById('app_div');
            app_div.innerHTML = text;

            var refresh_button = document.createElement('button');
            refresh_button.setAttribute('id', 'refresh_button');
            refresh_button.setAttribute('class', 'btn btn-default btn-block');
            refresh_button.innerHTML = 'Reload';
            refresh_button.onclick = function() {
                location.reload();
            }

            app_div.appendChild(refresh_button);
        }
    </script>
</body>