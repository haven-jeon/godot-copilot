@tool
extends "res://addons/copilot/LLM.gd"

var URL: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key={api-key}"
const SYSTEM_TEMPLATE = """**You are a brilliant coding assistant for the game-engine Godot. The version used is Godot 4.2, and all code must be valid GDScript!
That means the new GDScript 2.0 syntax is used.

You may only answer in code, never add any explanations. 
In prompt, there will be an !INSERT_CODE_HERE! tag. 
Only respond with plausible code that may be inserted at that point.
Generate code with appropriate korean descriptions on important parts of the code. 
Never repeat the full script, only the parts to be inserted.
You may continue whatever word or expression was left unfinished before the tag.
Make sure indentation matches the surrounding context.
Do not start with "```gdscript\n"**"""
const INSERT_TAG = "!INSERT_CODE_HERE!"
const MAX_LENGTH = 8500

class Message:
    var role: String
    var parts: Array
    
    func get_json():
        return {
            "role": role,
            "parts": parts
        }

const ROLES = {
    "SYSTEM": "user",
    "USER": "user",
    "ASSISTANT": "assistant"
}

func _get_models():
    return [
        "gemini-1.5-pro"
    ]

func _set_model(model_name):
    model = model_name

func _send_user_prompt(user_prompt, user_suffix):
    var messages = format_prompt(user_prompt, user_suffix)
    get_completion(messages, user_prompt, user_suffix)

func format_prompt(prompt, suffix):
    var messages = []
    var system_prompt = SYSTEM_TEMPLATE
    
    var combined_prompt = prompt + suffix
    var diff = combined_prompt.length() - MAX_LENGTH
    if diff > 0:
        if suffix.length() > diff:
            suffix = suffix.substr(0,diff)
        else:
            prompt = prompt.substr(diff - suffix.length())
            suffix = ""
    var user_prompt = prompt + INSERT_TAG + suffix
    
    var msg = Message.new()
    msg.role = ROLES.SYSTEM
    msg.parts = [{"text": system_prompt + "\n\n\n\n" + user_prompt}]
    messages.append(msg.get_json())
    
    return messages

func get_completion(messages, prompt, suffix):
    print(messages)
    var body = {
        "contents": messages,
        "generationConfig": {
            "stopSequences": [
                ##"\n\n" if allow_multiline else "\n" 
            ],
            "temperature": 0.7,
            "maxOutputTokens": 500
        }
    }
    var headers = [
        "Content-Type: application/json"
    ]
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.connect("request_completed",Callable(self,"on_request_completed").bind(prompt, suffix))
    var json_body = JSON.stringify(body)
    var buffer = json_body.to_utf8_buffer()
    var url = URL.format({"api-key": api_key})
    var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
    print(url)
    print(headers)
    if error != OK:
        emit_signal("completion_error", null)

func on_request_completed(result, response_code, headers, body, pre, post):
    var test_json_conv = JSON.new()
    test_json_conv.parse(body.get_string_from_utf8())
    var json = test_json_conv.get_data()
    var response = json
    print(response)
    if response == null or !response.has("candidates") :
        emit_signal("completion_error", response)
        return
    var completion = response.candidates[0].content.parts[0]
    var codes: String = completion.text.replacen("```gdscript", "").replacen("```", "")
    emit_signal("completion_received", codes, pre, post)
