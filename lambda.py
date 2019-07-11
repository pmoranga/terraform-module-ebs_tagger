import boto3
import os
import ast
import pprint
import logging
import sys
from time import sleep

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.resource('ec2')
client = boto3.client('ec2')

if 'LAMBDA_TAGS' not in os.environ.keys():
  logger.fatal('Environment variable LAMBDA_TAGS not defined.')
  exit(1)

tags = dict(item.split("=") for item in (os.environ['LAMBDA_TAGS']).split(","))
logger.info("Tags to add: %s", tags)



def ebs_tagger_handler(event, context):
  logger.info('Event payload content: %s', event)

  sleep(5)

  if event['source'] == "aws.ec2" : 
    if event['detail']['event'] == "createVolume":
      try:
        volume_id = event['resources'][0].split('/')[1]
      except:
        logger.fatal("Could not extract volume name from arn, %s",event['resources'], exc_info=1)
        exit(1)
      logger.info("Volume_ID extracted from payload: %s", volume_id)
      process_volume(volume_id, context)
    else:
      logger.info('No actions for event "%s", stopping', event['detail']['event'])
  else:
    logger.error("Received Event Source no supported: " + event['source'])
    sys.exit(1)

def process_volume(volume_id, context):
  add_tags = []
  added_tags = []

  try:
    volumes = ec2.volumes.filter(Filters=[{'Name': 'volume-id', 'Values': [volume_id]}])
  except botocore.exceptions.ClientError:
    logger.error("Volume not found {}".format(volume_id),exc_info=1)
    sys.exit(1)

  for vol in volumes:
    logger.info('Updating tags for %s, current state is %s',vol.id, vol.state.upper())
    logger.info('Current tags: %s', vol.tags)

    # volume_tags = map(lambda x: {x['Key']:x['Value']},vol.tags)
    # pprint(volume_tags)
    existing_keys = list( map(lambda x: x['Key'],vol.tags) )
    
    for t in tags.keys():
      if t not in existing_keys:
        add_tags.append({'Key': t, 'Value': tags[t]})
        added_tags.append(t)
      else: 
        logger.info('%s already has tag "%s". Skipping', volume_id, t)

    if len(add_tags) > 0:
      add_tags.append({'Key':'tags_added_by_lambda_arn', 'Value': context.invoked_function_arn })
      add_tags.append({'Key':'tags_added_by_lambda_function_name', 'Value': context.function_name})
      add_tags.append({'Key':'tags_added', 'Value': ",".join(added_tags)})
      logger.info('Adding the following tags: %s', " ".join(added_tags))
      logger.info('Creating tags: %s', add_tags)
    
      r = client.create_tags(
        Resources=[ vol.id ],
        Tags=add_tags
      )

      logger.info("Done! Return %s", r)    
    else:
      logger.info("No new tags to set!")
    

    




