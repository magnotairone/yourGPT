# TAG-Powered PDF Explorer: A Conversational Interface for Your Documents

_The RAG-Powered PDF Explorer helps you create `yourGPT`!_

This Shiny app combines the power of OpenAI's GPT-4o-mini model and Pinecone's vector database to allow users to upload and interact with their PDF documents in a conversational manner. It seamlessly integrates R and Python through the reticulate package, enabling R users to leverage large language models (LLMs) implemented in Python. The app employs the Retrieval-Augmented Generation (RAG) technique to enhance user queries with relevant document context, enabling a deeper and more efficient exploration of the content.

### How to Use the App

This mini tutorial will guide you through the steps required to start interacting with your PDF using the **RAG-Powered PDF Explorer**.

1. **Access the Setup Page**:
   - When you open the app, the first tab will be the **Setup and Instructions** tab. 
   - Here, you will find fields to input your **OpenAI API key** and **Pinecone API key**. 
   - Additionally, you must provide a **Pinecone Index Name**, which will be used to store the embeddings generated from your document. If the index name you provide already exists in your Pinecone account, it will be reused; otherwise, a new index will be automatically created to store the embeddings.
   
   
2. **Upload Your PDF**:
   - After entering your API keys and index name, upload the PDF file you wish to interact with by clicking the "Upload PDF File" button and selecting a `.pdf` file from your computer.

3. **Generate Your GPT**:
   - Click on the **"Generate your GPT"** button. The app will process your PDF, embedding the contents for future queries.
   - You will see a progress bar as the document is split into chunks, embedded, and prepared for interaction. Notifications will inform you of each step.

4. **Move to the Chat Tab**:
   - Once the setup is complete, the app will automatically populate the necessary fields in the **"Chat with your data"** tab.
   - You will see fields for the **OpenAI API Key**, **Pinecone API Key**, and **Pinecone Index Name** already populated.

5. **Start the Conversation**:
   - In the **"Chat with your data"** tab, click the **"Start Chat"** button. This will initialize the chat interface, where you can begin interacting with your uploaded PDF.
   - Simply type your questions in the chat box, and the app will respond with context-aware answers, retrieving relevant portions of the document to provide precise responses.
   - If your question falls outside the scope of the PDF content, the model will inform you that it should not provide a response.

6. **Continue Exploring**:
   - You can ask follow-up questions or explore other parts of the document by continuing the conversation in the chat interface.

### Technical Specifications:

- **Integration with Python**: Using the **reticulate** package, the app combines the strengths of R and Python. This enables R users to access and interact with **LLMs (Large Language Models)**, such as GPT-4o-mini, that are implemented in Python's LangChain. This powerful combination allows the Shiny app to process PDFs, generate embeddings, and perform sophisticated document queries.
- **RAG System**: Uses Retrieval-Augmented Generation to provide precise, context-aware responses by retrieving relevant pieces of the document.
- **Back-End**: Integration with OpenAI for GPT-4o-mini queries and Pinecone for vector search.
- **Pinecone Indexing**: The embedded PDF content is stored in Pinecone's vector database, allowing for efficient retrieval of relevant document sections during queries.
- **Langchain**: Langchain manages the integration between GPT-4o-mini and Pinecone, ensuring contextually accurate responses based on relevant sections of the PDF.
- **Shiny**: The entire app is built using R's Shiny framework, ensuring a smooth and dynamic user experience with seamless Python integration for the document analysis and LLM processing.


### Potential Use Cases:

- **Document Summarization**: Ask questions to summarize lengthy reports or legal documents.
- **Data Exploration**: Quickly find specific information from large datasets, research papers, or business reports.
- **Educational Tool**: Interactive learning by asking questions directly to textbooks or lecture notes.
