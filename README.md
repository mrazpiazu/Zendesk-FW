# Zendesk-FW

This is a Zendesk App which provides Forwarding feature to Zendesk platform through AWS Simple Email Service.

The App is developed over an Instabug - Zendesk integration and therefore it does trim some data like "Title:  " and "Report:".
It will also manage attachments based on Instabug reporting format, so if you are not using Instabug to report to Zendesk you
may need to modify the code both in app.py and start.tpl template.

There are two folders in this rep:
  - app_local should be compiled through ZAT v2 and uploaded to Zendesk as a Private Application
    - This only contains basic Zendesk App files like the HTML with the iframe integration for the Python app
  - app_remote should be run in server with Python3

app_remote/views/start.tpl contains both the HTML and the JavaScript + jQuery code and can be updated from server side.

This App requires a data.json file placed in app_remote with the following format:

    "zendesk": {
        "url": "https://ZENDESK-SUB-DOMAIN.zendesk.com/api/v2/tickets/",
        "user": "ZENDESK-USER-EMAIL",
        "token": "ZENDESK-USER-TOKEN",
        "categories": {
            # ZENDESK CUSTOM FIELDS DICT
            # FORMAT: "name":"CUSTOM-FIELD-ID"
        },
        "new_tags": [
            # LIST OF TAGS TO ADD TO THE TICKET
        ]
    },
    "aws": {
        "region": "AWS-REGION",
        "key": "AWS-KEY",
        "secret": "AWS-SECRET"
    },
    "email": {
        "sender": "SENDER-INFO",
        "admin": "ADMIN-EMAIL",
        "dest_in": { # Unlimited Internal receivers
            "External Receiver 1":"example1@domain.com",
            "External Receiver 2":"example2@domain.com"
        },
        "dest_ext": { # Unlimited External receivers
            "External Receiver 1":"example1@domain.com",
            "External Receiver 2":"example2@domain.com",
        }
    }    

The App will require to modify app_local/manifest.json as of data["location"]["support"]["ticket_sidebar"] to include server's URL/IP, before compiling app_local and uploading it to Zendesk.

The App will require to modify the destinations_list array of objects in start.tpl with the desired destinations and types. These destinations should match with data.json's data['email'] "dest_in" or "dest_ext" receivers' names.

The App will require to modify the array passed through client.get() in function sendEmail() and the object data that is passed through ajax in start.tpl, to customize or remove the custom fields that are being used on this code.

Future updates will make these changes more efficient and scalable.
