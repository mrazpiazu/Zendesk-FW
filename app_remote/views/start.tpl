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
                {
                    'type': 'other',
                    'dest': 'Enter email'
                }
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

                let dest_div = document.createElement('div');
                dest_div.setAttribute('id', dest.replace(' ', '_')+'_div');

                let button = document.createElement("button");
                button.setAttribute('class', 'btn btn-default btn-block');
                button.setAttribute("id", type+'_'+dest);
                button.innerHTML = dest;
                button.addEventListener("click", function(event) {
                    event.stopPropagation();
                    validateSend(dest, type);
                });
                
                dest_div.appendChild(button);
                type_div.appendChild(dest_div);
            }
        }

        function validateSend(destination, type) {
            var app_div = document.getElementById('app_div');
            var button = document.getElementById(type+'_'+destination);
            var button_div = document.getElementById(type);
            button_div.style.display = 'block';

            if (!document.getElementById(destination.replace(' ', '_')+'_text_box')) {
                var linebreak = document.createElement('br');
                var text_box = document.createElement("input");
                text_box.setAttribute('id', destination.replace(' ', '_')+'_text_box');
                text_box.setAttribute("type", "text");

                var text_button = document.createElement("button");
                text_button.setAttribute('id', destination.replace(' ', '_')+'_text_button');
                text_button.setAttribute('class', 'btn btn-default btn-block');
                text_button.innerHTML = 'Confirm Destination: '+destination

                button.appendChild(linebreak);
            }

            else {
                var text_box = document.getElementById(destination.replace(' ', '_')+'_text_box');
                var text_button = document.getElementById(destination.replace(' ', '_')+'_text_button');
            }

            button.appendChild(text_box);
            button.appendChild(text_button);
            text_box.focus();

            text_button.onclick = function() {
                if (type != 'other' && text_box.value == destination) {
                    sendEmail(destination, type);
                }

                else if (type == 'other') {
                    sendEmail(text_box.value, type);
                }

                else {
                    app_div.innerHTML = 'No destination confirmed.'
                }
            }
        }

        function sendEmail(destination, type) {

            instabug_integration = true;

            $("body").css("cursor", "progress");

            let custom_fields = [
                {
                    "name": "category",
                    "id": "360009064098"
                },
                {
                    "name": "app",
                    "id": "360009089098"
                }
            ]

            get_list = [
                'ticket.id',
                'ticket.status', 
                'ticket.tags', 
                'ticket.subject', 
                'ticket.description',
                'ticket.requester',
                'ticket.comments'
            ];

            for (field of custom_fields) {
                get_list.push('ticket.customField:custom_field_'+field.id);
            }

            client.get(get_list).then(
                function(data) {
                    var ticket_title = data['ticket.subject'].replace(/(\r\n|\n|\r)/gm, "");
                    var ticket_id = data['ticket.id'];
                    var ticket_status = data['ticket.status'];
                    var ticket_tags = data['ticket.tags'];
                    var ticket_requester = data['ticket.requester'].email;
                    var ticket_description = data['ticket.description'];
                    var ticket_full_description = data['ticket.description'].replace(/\n/g, "<br />")
                    var ticket_attachments = [];

                    for (field of custom_fields) {
                        field.value = data['ticket.customField\:custom_field_'+field.id]

                        if (field.name == 'category') {
                            var category = field.name;
                        }

                        if (field.name == 'app') {
                            var app = field.value;
                        }
                    }

                    if (type == 'apps' && (destination.toLowerCase() != app)) {
                        updateApp('<b>App and Destination don\'t match</b>', destination, type);
                        return;
                    }

                    for (var i = 0; i < data['ticket.comments'].length; i++) {
                        for (var x = 0; x < data['ticket.comments'][i]["imageAttachments"].length; x++) {
                            ticket_attachments.push(data['ticket.comments'][i]["imageAttachments"][x]["contentUrl"]);
                        }
                    }

                    if (instabug_integration == true) {
                        if (instabugFormat(data['ticket.description'], "attachment") != false) {
                            ticket_attachments.push(instabugFormat(data['ticket.description'], "attachment"));
                        }
                        
                        ticket_description = instabugFormat(data['ticket.description'], "description");
                    }

                    ticket_description = "<b>Requester Email: </b>" + ticket_requester + "<br /><br ><b>Previous communication as below:</b><br /><br />" + ticket_description;

                    ticket_description = ticket_description.replace(/\n/g, "<br />");

                    var data = {
                        destination: destination,
                        dest_type: type,
                        id: ticket_id,
                        status: ticket_status,
                        tags: ticket_tags,
                        title: ticket_title,
                        requester: ticket_requester,
                        description: ticket_description,
                        full_description: ticket_full_description,
                        attachments: ticket_attachments,
                        custom_fields: JSON.stringify(custom_fields)
                    }

                    if (category) {
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
                        console.log(response);
                        updateApp(response, destination, type);
                    }
                }
            });
        }

        function instabugFormat(data, type) {
            if (type == "attachment") {
                if (data.indexOf("**Non Image Attachments:**") != '-1') {
                    attachment = data.split('mp4](')[1];
                    return attachment.slice(0, -2);
                }

                else {
                    return false;
                }
            }

            else if (type == "description") {
                ticket_description = data.split('Reported')[0];
                return ticket_description.split('Title:	')[1];
            }
        }

        function updateApp(text, destination, type) {
            if (document.getElementById(destination.replace(' ', '_')+'_text_box')) {
                var text_box = document.getElementById(destination.replace(' ', '_')+'_text_box');
                var text_button = document.getElementById(destination.replace(' ', '_')+'_text_button');
                var app_div = document.getElementById(destination+'_div');
            }

            else {
                var text_box = document.getElementById('Enter_email_text_box');
                var text_button = document.getElementById('Enter_email_text_button');
                app_div = document.getElementById('Enter_email_div');
            }

            text_box.remove();
            text_button.remove();
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