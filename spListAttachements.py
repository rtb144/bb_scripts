import requests

# Configuration
tenant_id = 'your_tenant_id'
client_id = 'your_client_id'
client_secret = 'your_client_secret'
site_url = 'https://your_army365_domain.sharepoint.com/sites/yoursite'
list_name = 'your_list_name'

# Acquire Access Token
token_url = f'https://login.microsoftonline.us/{tenant_id}/oauth2/v2.0/token'
token_payload = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'https://your_army365_domain.sharepoint.com/.default'
}

token_response = requests.post(token_url, data=token_payload)
token_response.raise_for_status()
access_token = token_response.json().get('access_token')

# Get List Items with Attachments
headers = {
    'Authorization': f'Bearer {access_token}',
    'Accept': 'application/json;odata=verbose'
}

list_items_url = f'{site_url}/_api/web/lists/getbytitle(\'{list_name}\')/items?$expand=AttachmentFiles'
list_items_response = requests.get(list_items_url, headers=headers)
list_items_response.raise_for_status()
list_items = list_items_response.json()['d']['results']

# Download Attachments
for item in list_items:
    if item.get('AttachmentFiles'):
        for attachment in item['AttachmentFiles']['results']:
            attachment_url = attachment['ServerRelativeUrl']
            attachment_name = attachment['FileName']
            attachment_response = requests.get(f'{site_url}{attachment_url}', headers=headers)
            attachment_response.raise_for_status()

            # Save the attachment
            with open(attachment_name, 'wb') as file:
                file.write(attachment_response.content)
            print(f'Downloaded {attachment_name}')

print('All attachments downloaded.')
