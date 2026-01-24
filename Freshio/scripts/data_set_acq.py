import os
import requests
import time
from kaggle.api.kaggle_api_extended import KaggleApi
from dotenv import load_dotenv


def wait_for_connection(dataset_id):
    """Pause the downloading process until connection is restored."""
    """The restart that paticular download section"""
    print(f"\n{(" "*6)}[!] Dataset no. {dataset_id}: Processinterrupted.", end="", flush=True)

    while True:
        try :
            requests.get("https://8.8.8.8", timeout=3)
            print(f"\n{(" "*6)}[✓] Dataset no. {dataset_id}: Resuming the download process.")
            return
    
        except:
            time.sleep(5)
            print(".", end="", flush=True)


# Load credentials from .env
load_dotenv()

remote_data = [
    "sriramr/fruits-fresh-and-rotten-for-classification",
    "swoyam2609/fresh-and-stale-classification"
]
local_data = []

# Authenticate using the official API
api = KaggleApi()
api.authenticate()

print("Data set downloading process was commenced...")

for i in range(len(remote_data)):

    dataset_id = i+1
    print(f"\n{(" "*3)}Data set {dataset_id}: Download process was comenced.")
    target_folder = os.path.join(os.getcwd(), f"dataset_{dataset_id}")
    local_data.append(target_folder)

    while True:
        try :
            print(f"{(" "*6)}Data set {dataset_id}: Downloading directly to {target_folder}.")
            api.dataset_download_files(remote_data[i], path=target_folder, unzip=True)
            print(f"{(" "*6)}Data set {dataset_id}: Successfully downloaded to {target_folder}.")
            break

        except Exception as e:
            print(f"{(" "*6)}[X] Data set {dataset_id}: Due to - {e}")
            wait_for_connection(dataset_id)

    print(f"{(" "*3)}Data set {dataset_id}: Download process was completed.")

print("\nAll datasets were Successfully downloaded...")

# Print all downloaded datasets
print("\nAll downloaded datasets...")
for j in range(len(local_data)):
    print(f"Data set no. {j+1}: {local_data[j]}")
