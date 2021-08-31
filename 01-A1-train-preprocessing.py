"""
Script to use Covseq (https://github.com/boxiangliu/covseq) to read genome sequences from FASTA files 
and identify different regions (generates a TSV).
"""
import os
import glob


covseq_scipt_path = "covseq/"
unprocessed_path = "data/fasta_preprocessing/unprocessed/"
processed_path = "data/fasta_preprocessing/processed/"
segmented_path = "data/fasta_preprocessing/segmented/"


def clean_fasta_files():
    raw_fasta_files = glob.glob(os.path.join(unprocessed_path, "**/*.fasta"), recursive=True)
    for file in raw_fasta_files:
        filename = os.path.basename(file)
        out_file = os.path.join(processed_path, filename)
        print(out_file)
        try:
            cmd = f"sed -e 's/ /-/g' -e 's/|/_/g' '{file}' > '{out_file}'"
            os.system(cmd)
        except Exception as e:
            print(f'FAILED for file. Reason: {e}')
        
def get_tsv_with_covseq():
    processed_fasta_files = glob.glob(f'{processed_path}/*.fasta')
    for file in processed_fasta_files:
        filename = os.path.basename(file)
        print(filename)
        out_folder = os.path.join(segmented_path, filename)
        os.system(f'mkdir -p {out_folder}')
        cmd = f"cd {covseq_script_path} && python annotation/annotation.py --fasta '{os.path.abspath(file)}' --out_dir '{os.path.abspath(out_folder)}'"
        os.system(cmd)

def main():
    clean_fasta_files()
    get_tsv_with_covseq()


if __name__ == '__main__':
    main()