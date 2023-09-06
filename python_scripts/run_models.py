import subprocess



#./main -m ./models/13B-chat/ggml-model-q4_0.bin -n 1024 --repeat_penalty 1.0 --color -i -r "User:" -f ./prompts/chat-with-bob.txt

def run_ggml_model(model_path):
    cmd = ['./main', '-m', model_path, '-n', '1024', '--repeat_penalty', '1.0', '--color', '-i', '-r', 'User:', '-f', './prompts/chat-with-bob.txt']
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout

