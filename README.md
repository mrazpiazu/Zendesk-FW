# Zendesk-FW

This is a Zendesk App which provides Forwarding feature to Zendesk platform through AWS Simple Email Service.

The App is developed over an Instabug - Zendesk integration and therefore it does trim some data like "Title:  " and "Report:".
It will also manage attachments based on Instabug reporting format, so if you are not using Instabug to report to Zendesk you
may need to modify the code.

There are two folders in this rep:
  - app_local should be compiled through ZAT v2 and uploaded to Zendesk as a Private Application
  - app_remote should be run in server with Python3

start.tpl contains both the HTML and the JavaScript + jQuery code and can be updated from server side.

This App requires a data.json file with the following format:

{
    "zendesk": {
        "url": "https://ZENDESK-SUB-DOMAIN.zendesk.com/api/v2/tickets/",
        "user": "ZENDESK-USER-EMAIL",
        "token": "ZENDESK-USER-TOKEN"
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
}

