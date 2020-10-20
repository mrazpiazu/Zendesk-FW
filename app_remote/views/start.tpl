<head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/combine/npm/@zendeskgarden/css-bedrock@7.0.21,npm/@zendeskgarden/css-utilities@4.3.0">
    <link href="https://cdn.jsdelivr.net/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <br>
    <div id='app_div'>
        <div id='buttons'>
        </div>
    </div>
    <script src="https://static.zdassets.com/zendesk_app_framework_sdk/2.0/zaf_sdk.min.js"></script>
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/emailjs-com@2.4.0/dist/email.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.5.1.min.js" integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" crossorigin="anonymous"></script>
    <script src="https://apis.google.com/js/platform.js" async defer></script>
    <script type=text/javascript>
        var client = ZAFClient.init();
        client.invoke('resize', { width: '100%', height: '380px' });

        createButtons()

        function createButtons() {

            var buttons_div = document.getElementById('buttons');

            const destinations_list = [
                {
                    'type': 'apps',
                    'dest': 'Pame'
                },
                {
                    'type': 'apps',
                    'dest': 'Tallinja'
                },
                {
                    'type': 'operators',
                    'dest': 'Muving'
                },
                {
                    'type': 'internal',
                    'dest': 'Test'
                },
                {
                    'type': 'internal',
                    'dest': 'Product Owner'
                },
                {
                    'type': 'internal',
                    'dest': 'CTO'
                },
                {
                    'type': 'internal',
                    'dest': 'IT'
                },
            ];

            var dest_types = [];

            for (let destination of destinations_list) {
                let type = destination.type;

                if (!dest_types.includes(type)) {
                    dest_types.push(type);
                }
            }

            for (let type of dest_types) {
                let type_div = document.createElement("div");
                type_div.setAttribute("id", type);
                type_div.style.display = "none";

                let type_button = document.createElement("button");
                type_button.setAttribute("id", type+"_button");
                type_button.setAttribute('class', 'btn btn-default btn-block');
                type_button.innerHTML = type.charAt(0).toUpperCase() + type.slice(1);
                type_button.addEventListener("click", function() {
                    if (type_div.style.display == "none") {
                        type_div.style.display = "block";
                    }

                    else {
                        type_div.style.display = "none";
                    }
                });

                type_button.appendChild(type_div);
                buttons_div.appendChild(type_button);
            }

            for (let destination of destinations_list) {
                let dest = destination.dest;
                let type = destination.type;

                let type_div = document.getElementById(type);

                let button = document.createElement("button");
                button.setAttribute('class', 'btn btn-default btn-block');
                button.setAttribute("id", type+'_'+dest);
                button.innerHTML = "FW to "+dest;
                button.addEventListener("click", function(event) {
                    event.stopPropagation();
                    validateSend(dest, type);
                });
                
                type_div.appendChild(button);
            }
        }

        function validateSend(destination, type) {
            var app_div = document.getElementById('app_div');
            var button = document.getElementById(type+'_'+destination);
            var button_div = document.getElementById(type);
            button_div.style.display = 'block';

            if (!document.getElementById(destination+'_text_box')) {
                var linebreak = document.createElement('br');
                var text_box = document.createElement("input");
                text_box.setAttribute('id', destination+'_text_box');
                text_box.setAttribute("type", "text");

                var text_button = document.createElement("button");
                text_button.setAttribute('id', destination+'_text_button');
                text_button.setAttribute('class', 'btn btn-default btn-block');
                text_button.innerHTML = 'Confirm Destination: '+destination

                button.appendChild(linebreak);
            }

            else {
                var text_box = document.getElementById(destination+'_text_box');
                var text_button = document.getElementById(destination+'_text_button');
            }

            button.appendChild(text_box);
            button.appendChild(text_button);
            text_box.focus();

            text_button.onclick = function() {
                if (text_box.value == destination) {
                    sendEmail(destination, type);
                }

                else {
                    app_div.innerHTML = 'No destination confirmed.'
                }
            }
        }

        function sendEmail(destination, type) {

            $("body").css("cursor", "progress");

            client.get([
                'ticket.id',
                'ticket.status', 
                'ticket.tags', 
                'ticket.subject', 
                'ticket.description',
                'ticket.requester',
                'ticket.comments',
                'ticket.customField:custom_field_360009064098',
                'ticket.customField:custom_field_360009089098']).then(
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

                    if (type == 'apps' && (destination.toLowerCase() != app)) {
                        updateApp('<b>App and Destination don\'t match</b>', type);
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
                        ajaxCall(data, destination, type);
                    }

                    else {
                        $("body").css("cursor", "default");
                        updateApp('<b>A Category needs to be selected before forwarding an email', destination, type);
                    }
                }
            );
        }

        function ajaxCall(data, destination, type) {
            $.ajax({
            method: 'GET',
            url: 'mail',
            data: data,
            success: function(response) {
                $("body").css("cursor", "default");

                if (response) {
                    updateApp(response, destination, type);
                }
            }
            });
        }

        function updateApp(text, destination, type) {
            var text_box = document.getElementById(destination+'_text_box');
            var text_button = document.getElementById(destination+'_text_button');
            text_box.remove();
            text_button.remove();

            app_div = document.getElementById('app_div');
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