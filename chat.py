from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_core.chat_history import BaseChatMessageHistory
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.chains import create_history_aware_retriever
from langchain_openai import ChatOpenAI
from langchain_openai import OpenAIEmbeddings
from langchain_pinecone import PineconeVectorStore
from langchain.text_splitter import CharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader
from langchain_pinecone import PineconeVectorStore
from langchain_openai import OpenAIEmbeddings
from pinecone.grpc import PineconeGRPC as Pinecone
from pinecone import ServerlessSpec
import os

class RAGChatbot:
    def __init__(self, openai_api_key, pinecone_api_key, pinecone_index):
        os.environ["OPENAI_API_KEY"] = openai_api_key
        os.environ['PINECONE_API_KEY'] = pinecone_api_key
        self.pinecone_index = pinecone_index
        self.embeddings = OpenAIEmbeddings(model="text-embedding-ada-002")

    def split_pdf(self, file_path):
        loader = PyPDFLoader(file_path)

        pages = loader.load()
        
        chunk_size = 4000
        chunk_overlap = 150
        
        document_splitter = CharacterTextSplitter(
            chunk_size=chunk_size, 
            chunk_overlap=chunk_overlap, 
            separator=" "
        )
        self.pdf_chunks = document_splitter.split_documents(pages)

    def create_embedding(self):
        pc = Pinecone(os.environ['PINECONE_API_KEY'])

        if self.pinecone_index not in pc.list_indexes().names():
            pc.create_index(
                name=self.pinecone_index,
                dimension=1536,
                metric="cosine",
                spec=ServerlessSpec(
                    cloud='aws', 
                    region='us-east-1'
                ) 
            )
            
        vectorstore_from_docs = PineconeVectorStore.from_documents(
            self.pdf_chunks,
            index_name=self.pinecone_index,
            embedding=self.embeddings
        )
        
    def validate_pinecone_index_name(self, name):
      pc = Pinecone(os.environ['PINECONE_API_KEY'])
      return name in pc.list_indexes().names()

    def init_llm(self):
        self.llm = ChatOpenAI(model='gpt-4o-mini', temperature=0)

        self.knowledge_base = PineconeVectorStore.from_existing_index(
            index_name=self.pinecone_index,
            embedding=self.embeddings
        )
        self.retriever = self.knowledge_base.as_retriever()

        self.contextualization_prompt = (
            'Given a chat history and the last question from the user, '
            'which might reference the context from the chat history, '
            'formulate an independent question that can be understood '
            'without the chat history. DO NOT answer the question, '
            'just reformulate it if necessary, otherwise, return it as it is.'
        )

        self.prompt_template = ChatPromptTemplate.from_messages(
            [
                ('system', self.contextualization_prompt),
                MessagesPlaceholder('chat_history'),
                ('human', '{input}'),
            ]
        )

        self.history_aware_retriever = create_history_aware_retriever(
            self.llm, self.retriever, self.prompt_template
        )

        self.final_prompt = (
            "You are an assistant for question-answering tasks about the context below. "
            "Use the following retrieved context snippets to answer "
            "the question. If you do not know the answer, say you "
            "do not know. If the question is outside the retrieved context, "
            "do not answer and just say it is outside the context.\n\n"
            "Context: {context}"
        )

        self.qa_prompt = ChatPromptTemplate.from_messages(
            [
                ('system', self.final_prompt),
                MessagesPlaceholder('chat_history'),
                ('human', '{input}'),
            ]
        )

        self.qa_chain = create_stuff_documents_chain(
            self.llm,
            self.qa_prompt
        )

        self.rag_chain = create_retrieval_chain(
            self.history_aware_retriever,
            self.qa_chain
        )

        self.sessions = {}

    def get_session_history(self, session_id: str) -> BaseChatMessageHistory:
        if session_id not in self.sessions:
            self.sessions[session_id] = ChatMessageHistory()
        return self.sessions[session_id]

    def get_response(self, question, session_id='abc123'):
        chat_rag_chain = RunnableWithMessageHistory(
            self.rag_chain,
            self.get_session_history,
            input_messages_key='input',
            history_messages_key='chat_history',
            output_messages_key='answer',
        )

        result = chat_rag_chain.invoke(
            {'input': question},
            config={'configurable': {'session_id': session_id}},
        )
        return result
