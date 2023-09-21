from h2o_helium import Helium
import os
import pandas as pd

# chat_interfaces = {}


class HeliumChatInterface:
    def __init__(self, chat_uuid, api_key) -> None:
        self.helium = Helium(address='https://playground.helium.h2o.ai', api_key=api_key)
        self.uploads = []
        self.chat_session_id = None
        self.session = None

    def start_chat_session(self, collection_id):
        self.chat_session_id = self.helium.create_chat_session(collection_id)
        self.session = self.helium.connect(self.chat_session_id)

    def stop_chat_session(self):
        if self.session is not None:
            self.session.disconnect()
            self.session = None
            self.chat_session_id = None
            
    def ask_question(self, question):
        if self.session is None:
            raise Exception("Chat session not started. Call start_chat_session first.")
        reply = self.session.query(question, timeout=10)
        return reply.content
    
    def initialize_collection(self, name, description):
        collection_id = self.helium.create_collection(name='Annual Reports', description='QAs from Annual Reports')
        return collection_id
    
    def upload_documents(self, folder_path):
        for filename in os.listdir(folder_path):
            file_path = os.path.join(folder_path, filename)
            with open(file_path, 'rb') as f:
                upload = self.helium.upload(filename, f)
                self.uploads.append(upload)

    def ingest_uploads(self, collection_id):
        self.helium.ingest_uploads(collection_id, self.uploads)

    def upload_csv_documents(self, folder_path):
        # Iterate over each CSV file in the directory
        '../data/annual reports/'
        for file_name in os.listdir(folder_path):
            if file_name.endswith('.csv'):
                file_path = os.path.join(folder_path, file_name)
                # Load your CSV file with questions
                df = pd.read_csv(file_path)

                # Create a new collection
                collection_id = self.helium.create_collection(name=file_name, description='Annual report')

                # Create a new chat session for the collection
                chat_session_id = self.helium.create_chat_session(collection_id)

                # Ask each question in the "questions" column
                with self.helium.connect(chat_session_id) as session:
                    for index, row in df.iterrows():
                        reply = session.query(row['Question'], timeout=10)
                        # Write the response to the "helium answer" column of the CSV
                        df.loc[index, 'Helium Answers'] = reply.content

                # Save the dataframe to a new CSV file
                df.to_csv(f'../data/annual reports/answers_{file_name}', index=False)
