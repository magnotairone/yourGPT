library(shiny)
library(shinyChatR)
library(shinyjs)
library(shinythemes)
library(shinyWidgets)

# reticulate::use_virtualenv("C:/Users/m_tai/Documents/repos/ggplotGPT/ggplotgpt")
reticulate::virtualenv_create("ggplotgpt")

reticulate::virtualenv_install(envname = "ggplotgpt",
                               packages = c(
                                 "langchain",
                                 "langchain-community",
                                 "pypdf",
                                 "pinecone",
                                 "langchain_pinecone",
                                 "langchain-openai",
                                 "pinecone-client[grpc]",
                                 "langchain_openai"
                               ))

reticulate::use_virtualenv("ggplotgpt")


reticulate::py_run_file("chat.py")
reticulate::py_run_file("init_config.py")

define_setup <- function(openai_api_key, pinecone_api_key, pinecone_index, file_path = NULL) {
  reticulate::py$init_config(openai_api_key, pinecone_api_key, pinecone_index)
  
  reticulate::py_run_file("init_chat.py")
  
  if (!is.null(file_path)) {
    reticulate::py$split_pdf(file_path)
    reticulate::py$create_embedding()
  }
  
  if(reticulate::py$validate_pinecone_index_name(pinecone_index)) {
    reticulate::py$init_llm()
    return(TRUE)
  }
  else
    return(FALSE)
}

get_chat_response <- function(question, session_id = "abc123") {
  result = reticulate::py$get_response(question, session_id)
  return(result$answer)
}

csv_path <- "chat.csv"
session_id <- as.character(round(runif(1, 1000000000000, 9999999999999)))
send_message_button_id <- paste0(session_id, "-chatFromSend")
chat_user <- "You"
bot <- "yourGPT"
bot_initial_message <- "Hello! Ask me anything about your uploaded pdf!"

if (file.exists(csv_path)) {
  file.remove(csv_path)
}

chat_data <- shinyChatR:::CSVConnection$new(csv_path, n = 100)

ui <- fluidPage(
  theme = shinytheme("flatly"),
  
  useShinyjs(),
  
  navbarPage("RAG Chat", id = "tabs",
             
             tabPanel("Setup and Instructions",
                      sidebarLayout(
                        sidebarPanel(
                          tags$h4("Configuration for new PDF data", style = "color: #337ab7;"),
                          passwordInput("openai_key", "OpenAI Access Key:", value = ""),
                          passwordInput("pinecone_key", "Pinecone Access Key:", value = ""),
                          textInput("pinecone_index", "Pinecone Index Name", value = ""),
                          fileInput("pdf_file", "Upload PDF File", accept = c(".pdf")),
                          actionButton("submit_btn", "Generate your GPT", 
                                       icon = icon("cogs"), 
                                       style = "color: white; background-color: #337ab7; border-color: #2e6da4;"),
                          width = 3
                        ),
                        mainPanel(
                          tags$h3("Setup your application", style = "color: #337ab7;"),
                          p("Get ready to", strong("talk to your PDF!"), "This app lets you have an interactive conversation with your PDF document, powered by OpenAI and Pinecone."),
                          p("Given a PDF file, this app will create a RAG system that integrates with ChatGPT 4o-mini and will enable you to ask questions about the PDF content."),
                          tags$ul(
                            tags$li("Your OpenAI API access key: This key will be used to interact with the language model. Learn more about the OpenAI API", tags$a(href = "https://beta.openai.com/docs/", "here"), "."),
                            tags$li("Your Pinecone API access key: This key is necessary for vector database operations. Learn more about the Pinecone API", tags$a(href = "https://docs.pinecone.io/docs/overview).", "here"), "."),
                            tags$li("The name of your Pinecone index: If the index does not exist in your Pinecone account, it will be created automatically."),
                            tags$li("A PDF file: Upload the document you want to query through the chat interface.")
                          ),
                          p("Please note: Using the OpenAI API has associated costs. You will be charged based on usage. Pinecone is free for indexes up to 2GB."),
                          p("Once these details are provided, click the 'Generate your GPT' button to start interacting with your PDF."),
                          div(id = "loading_bar", style = "display:none;",
                              progressBar(id = "progress", value = 0, display_pct = TRUE)
                          ),
                          width = 9
                        )
                      )
             ),
             
             tabPanel("Chat with your data",
                      sidebarLayout(
                        sidebarPanel(
                          tags$h4("Chat Configuration", style = "color: #337ab7;"),
                          passwordInput("openai_key_chat", "OpenAI API Key", value = ""),
                          passwordInput("pinecone_key_chat", "Pinecone API Key", value = ""),
                          textInput("pinecone_index_input", "Pinecone Index Name", value = ""),
                          actionButton("start_chat_btn", "Start Chat", 
                                       icon = icon("play"), 
                                       style = "margin-top: 25px; color: white; background-color: #5cb85c; border-color: #4cae4c;", 
                                       disabled = TRUE),
                          width = 3
                        ),
                        mainPanel(
                          div(id = "chat_panel", style = "display:none;",
                              chat_ui(id = session_id, ui_title = bot_initial_message, height = "500px", width = "100%")
                          )
                        )
                      )
             )
  )
)

server <- function(input, output, session) {
  
  observe({
    if (nchar(input$openai_key) > 0 && nchar(input$pinecone_key) > 0 && 
        nchar(input$pinecone_index) > 0 && !is.null(input$pdf_file)) {
      shinyjs::enable("submit_btn")
    } else {
      shinyjs::disable("submit_btn")
    }
  })
  
  observeEvent(input$submit_btn, {
    shinyjs::show("loading_bar")
    updateProgressBar(session = session, id = "progress", value = 0)
    
    updateProgressBar(session = session, id = "progress", value = 10)
    
    tryCatch({
      define_setup(input$openai_key, input$pinecone_key, input$pinecone_index, input$pdf_file$datapath)
      showNotification("Setting up the API keys", type = "message")
      
      updateProgressBar(session = session, id = "progress", value = 25)
      showNotification("Splitting your PDF into pieces", type = "message")
      
      updateProgressBar(session = session, id = "progress", value = 50)
      showNotification("Creating embeddings with your data", type = "message")
      
      updateProgressBar(session = session, id = "progress", value = 75)
      showNotification("Connecting the LLM with your data", type = "message")
      
      updateProgressBar(session = session, id = "progress", value = 100)
      shinyjs::hide("loading_bar")
      updateTextInput(session, "openai_key_chat", value=input$openai_key)
      updateTextInput(session, "pinecone_key_chat", value=input$pinecone_key)
      updateTextInput(session, "pinecone_index_input", value=input$pinecone_index)
      shinyjs::enable("start_chat_btn")
      updateNavbarPage(session, "tabs", "Chat with your data")
    }, error = function(e) {
      shinyjs::hide("loading_bar")
      show_alert(title="Error", 
                 text = e$message, 
                 type = "error")
    })
  })
  
  observe({
    if (nchar(input$openai_key_chat) > 0 && nchar(input$pinecone_key_chat) > 0 && 
        nchar(input$pinecone_index_input) > 0) {
      shinyjs::enable("start_chat_btn")
    } else {
      shinyjs::disable("start_chat_btn")
    }
  })
  
  observeEvent(input$start_chat_btn, {
    pinecone_index <- input$pinecone_index_input
    openai_key <- input$openai_key_chat
    pinecone_key <- input$pinecone_key_chat
    
    tryCatch({
      if (nchar(pinecone_index) > 0 && nchar(openai_key) > 0 && nchar(pinecone_key) > 0) {
        result = define_setup(openai_key, pinecone_key, pinecone_index)
        
        if(!result) {
          show_alert(title="Error", 
                     text = "Invalid Pinecone index name. Please go to 'Setup' tab and define a new index.", 
                     type = "error")
        } else {
          if (file.exists(csv_path)) {
            file.remove(csv_path)
          }
          
          chat_data <- shinyChatR:::CSVConnection$new(csv_path, n = 100)
          
          shinyjs::show("chat_panel")
        }
        
      } else {
        showNotification("Please provide valid API keys and a Pinecone Index Name.", type = "error")
      }
    }, error = function(e) {
      shinyjs::hide("loading_bar")
      show_alert(title="Error", 
                 text = e$message, 
                 type = "error")
    })
    
    
    
  })
  
  chat <- chat_server(
    id = session_id,
    chat_user = chat_user,
    csv_path = csv_path
  )
  
  observeEvent(input[[send_message_button_id]], {
    dt <- chat_data$get_data()
    bot_message <- get_chat_response(dt[.N, text], session_id)
    chat_data$insert_message(user = bot,
                             message = bot_message,
                             time = strftime(Sys.time()))
  })
}

shinyApp(ui, server)
