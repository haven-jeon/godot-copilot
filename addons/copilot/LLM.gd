@tool
extends Node

var model: String
var api_key: String
var allow_multiline: bool
var end_point: String
var dep_name: String
var api_version: String

signal completion_received(completion, pre, post)
signal completion_error(error)

#Expects return value of String Array
func _get_models():
    return []

#Sets active model
func _set_model(model_name):
    model = model_name

#Sets API key
func _set_api_key(key):
    api_key = key

func _azure_end_point(ep):
    end_point = ep

func _azure_deployment_name(dn):
    dep_name = dn
    
func _azure_api_version(av):
    api_version = av

#Determines if multiline completions are allowed
func _set_multiline(allowed):
    allow_multiline = allowed

#Sends user prompt
func _send_user_prompt(user_prompt, user_suffix):
    pass


