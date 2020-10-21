import json
import requests
import boto3
from botocore.exceptions import ClientError
from bottle import route, run, template, request

@route('/sidebar')
def send_iframe_html():
    return template('start')

@route('/mail')
def send_mail():

    def update_ticket(data, tid):
        payload = json.dumps(data)
        url = zendesk_url + tid + '.json'
        user = zendesk_user + '/token'
        pwd = zendesk_token
        headers = {'content-type':'application/json'}

        response = requests.put(url, data=payload, auth=(user, pwd), headers=headers)

        if response.status_code == 200:
            response.close
            return True

        else:
            response.close
            return '<b>An error has occurred</b> during the <b>Update</b> process of this ticket.<br /><br /><b>Error Code: </b>'+str(response.status_code)+'.<br /><b>Response: </b>'+str(response.text)

    tags = request.query.getlist('tags[]')
    attachments = request.query.getlist('attachments[]')
    status = request.query.status
    tid = request.query.id
    destination = request.query.destination
    dest_type = request.query.type
    title = request.query.title
    requester = request.query.requester
    description = request.query.description
    full_description = request.query.full_description
    app = request.query.app
    zendesk_category_name_app = request.query.category

    with open('data.json') as json_file:
        data = json.load(json_file)
    
    zendesk_url = data['zendesk']['url']
    zendesk_user = data['zendesk']['user']
    zendesk_token = data['zendesk']['token']
    zendesk_category_id_app = data['zendesk']['categories']['app']
    new_tags = data['zendesk']['new_tags']

    aws_access_key = data['aws']['key']
    aws_access_key_secret = data['aws']['secret']
    aws_region = data['aws']['region']

    sender = data['email']['sender']
    admin = data['email']['admin']

    dest_ext = data['email']['dest_ext']
    dest_in = data['email']['dest_in']

    signature = data['email']['signature']

    if destination in dest_ext:
        description = '<b>Please contact the client below to address this issue.</b><br /><br />' + description + '<br /><br /><b>'+signature+'</b>'
        title = '['+destination+' Support]: '+title
        dest = dest_ext

    elif destination in dest_in:
        title = '[Zendesk Report - '+app.capitalize()+']: '+title
        requester = admin
        description = full_description
        dest = dest_in

    else:
        title = '[Zendesk Report - '+app.capitalize()+']: '+title
        requester = admin
        description = full_description
        dest_in[destination] = destination
        dest = dest_in


    if len(attachments) >= 1:
        description = description + "<br /><br /><b>Attachment(s):<br /></b>"
        for attachment in attachments:
            description = description + '<a href="'+ attachment +'">'+attachment+'</a><br />'

    else:
        pass


    if (status == 'closed' or status == 'solved') and ('sent'+destination.lower() in tags):
        return 'Ticket is already forwarded to '+destination

    else:
        pass

    
    new_tags.append('sent_'+destination.lower().replace(' ', '_'))

    for tag in new_tags:
        if tag not in tags:
            tags.append(tag)

    data = {
        'ticket': {
            "custom_fields": [
                {
                    "id": zendesk_category_id_app, 
                    "value": zendesk_category_name_app
                }
            ],
            'tags': tags,
            'status': 'solved'
        }
    }

    SENDER = sender
    RECIPIENT = dest[destination]
    AWS_REGION = aws_region
    SUBJECT = title
    BODY_TEXT = description
    BODY_HTML = description
    CHARSET = "UTF-8"

    #CONFIGURATION_SET = "ConfigSet"

    client = boto3.client('ses', aws_access_key_id = aws_access_key, aws_secret_access_key = aws_access_key_secret, region_name = AWS_REGION)


    try:
        response = client.send_email(
            Destination = {
                'ToAddresses': [
                    RECIPIENT,
                ],
                'BccAddresses': [
                    admin
                ]
            },
            ReplyToAddresses = [
                requester
            ],
            Message = {
                'Body': {
                    'Html': {
                        'Charset': CHARSET,
                        'Data': BODY_HTML,
                    },
                    'Text': {
                        'Charset': CHARSET,
                        'Data': BODY_TEXT,
                    },
                },
                'Subject': {
                    'Charset': CHARSET,
                    'Data': SUBJECT,
                },
            },
            Source = SENDER,
            #ConfigurationSetName=CONFIGURATION_SET,
        )
    except ClientError as e:
        return '<b>An error has occurred</b> during the <b>Forward</b> process of this ticket.<br /><br /><b>Response: </b>'+e.response['Error']['Message']

    else:

        if (destination in dest_ext) and (dest[destination] != admin):
            data = {
                'ticket': {
                    "custom_fields": [
                        {
                            "id": zendesk_category_id_app,
                            "value": zendesk_category_name_app
                        }
                    ],
                    'tags': tags,
                    'status': 'solved'
                }
            }
           
            response = update_ticket(data, tid)

            if response == True:
                return 'Ticket successfully forwarded to <br /><b>'+dest[destination]+'</b>'

            else:
                return response

        elif (destination in dest_in) or (destination == 'Test'):
            data = {
                'ticket': {
                    "custom_fields": [
                        {
                            "id": zendesk_category_id_app,
                            "value": zendesk_category_name_app
                        }
                    ],
                    'tags': tags,
                }
            }

            response = update_ticket(data, tid)

            if response == True:

                if dest[destination] == admin:
                    return 'Email FW was <b>successfully tested</b>'

                elif dest[destination] != admin:
                    return 'Email was succesfully forwarded to <br /><b>'+dest[destination]+'</b>'

            else:
                return response

run(host='localhost', port=8080, debug=True)