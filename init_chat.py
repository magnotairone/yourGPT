chatbot = RAGChatbot(os.environ["OPENAI_API_KEY"], os.environ['PINECONE_API_KEY'], os.environ['PINECONE_INDEX'])

def split_pdf(file_path):
  chatbot.split_pdf(file_path)
  
def create_embedding():
  chatbot.create_embedding()

def validate_pinecone_index_name(pinecone_index):
  return chatbot.validate_pinecone_index_name(pinecone_index)

def init_llm():
  chatbot.init_llm()

def get_response(pergunta, session_id = 'abc123'):
  response = chatbot.get_response(pergunta, session_id="session_123")
  return response
