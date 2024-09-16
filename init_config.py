def init_config(openai_api_key, pinecone_api_key, pinecone_index):
  os.environ["OPENAI_API_KEY"] = openai_api_key
  os.environ['PINECONE_API_KEY'] = pinecone_api_key
  os.environ['PINECONE_INDEX'] = pinecone_index

