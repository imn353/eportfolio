import os
import shutil
import zipfile
import requests
import urllib3

# Suppress the SSL warning — INEP's government server has a cert issue but is safe
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

YEARS = [str(i) for i in range(2010, 2021+1)]
URLS = [
    f"https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_{year}.zip"
    for year in YEARS
]

def download(url, dest_dir):
    filename = url.split("/")[-1]
    dest_path = os.path.join(dest_dir, filename)

    print(f"Downloading {filename}...")
    # verify=False bypasses SSL cert check — safe here as INEP is a known gov source
    response = requests.get(url, stream=True, verify=False, timeout=120)
    response.raise_for_status()

    total = int(response.headers.get("content-length", 0))
    downloaded = 0
    chunk_size = 1024 * 1024  # 1 MB chunks

    with open(dest_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=chunk_size):
            if chunk:
                f.write(chunk)
                downloaded += len(chunk)
                if total:
                    pct = downloaded / total * 100
                    print(f"\r  {pct:.1f}%  ({downloaded // (1024*1024)} MB / {total // (1024*1024)} MB)", end="", flush=True)
    print()  # newline after progress
    return dest_path

def find_csv_in_zip(zf):
    """Return the name of the first CSV entry inside the zip (case-insensitive)."""
    return next(
        (name for name in zf.namelist() if name.lower().endswith(".csv")),
        None
    )

if __name__ == "__main__":
    os.makedirs("./data", exist_ok=True)

    for year, url in zip(YEARS, URLS):
        try:
            zip_path = download(url, "./data")
        except Exception as e:
            print(f"ERROR downloading {year}: {e}")
            continue

        print(f"Extracting CSV for {year}...")
        try:
            with zipfile.ZipFile(zip_path, "r") as zf:
                csv_name = find_csv_in_zip(zf)
                if not csv_name:
                    print(f"Warning: no CSV found inside zip for {year}")
                    continue

                # Extract only the CSV, then rename it to {year}.csv
                zf.extract(csv_name, "./data/tmp")
                shutil.move(f"./data/tmp/{csv_name}", f"./data/{year}.csv")
                shutil.rmtree("./data/tmp", ignore_errors=True)
                print(f"Saved ./data/{year}.csv")

        except zipfile.BadZipFile as e:
            print(f"ERROR extracting {year}: {e}")
        finally:
            if os.path.exists(zip_path):
                os.remove(zip_path)

    print("\nAll done!")