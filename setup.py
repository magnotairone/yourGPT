def setup(OPENAI_API_KEY, PINECONE_API_KEY, PINECONE_INDEX):
  os.environ["OPENAI_API_KEY"] = OPENAI_API_KEY
  os.environ['PINECONE_API_KEY'] = PINECONE_API_KEY
  os.environ['PINECONE_INDEX'] = PINECONE_INDEX
