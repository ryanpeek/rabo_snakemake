import pandas as pd
m = pd.read_csv("samples/2022_metadata_seq_samples_joined.csv", header = 0)
PLATES = m['plate_barcode'].unique().tolist() 
SAMPLES = m['well_barcodefull'].unique().tolist() # well barcode
LANES = m['seqsomm'].unique().tolist() # somm
READS = ["1", "2"]
TMPDIR = "/scratch/rapeek"

#print(PLATES)
#print(SAMPLES)
#print(LANES)

rule all:
    input: 
        expand("outputs/bams/{lane}_{plate}_{sample}.sort.flt.bam.bai", lane = LANES, plate = PLATES, sample = SAMPLES),
	expand("outputs/stats/{lane}_{plate}_{sample}.sort.flt.bam.stats", lane = LANES, plate = PLATES, sample = SAMPLES),
	expand("outputs/stats/{lane}_{plate}_{sample}.depth", lane = LANES, plate = PLATES, sample = SAMPLES)
	#expand("outputs/pca/{lane}_pca_all.covMat", lane = LANES)

# starting at well split because plate split was run w deMultiplexML tool by MM.

rule well_split_fastq:
    input: expand("outputs/fastq_plate/{{lane}}_{{plate}}_R{read}.fastq", read = READS)
    output: expand("outputs/fastq_split/{{lane}}_{{plate}}_R{read}_{sample}.fastq", sample = SAMPLES, read = READS)
    threads: 1
    resources:
        mem_mb=2000,
	#tmpdir=TMPDIR,
        time=2880
    #benchmark: "benchmarks/well_split_fastq_{lane}_{plate}_R{read}_{sample}.tsv"
    params: outdir = "outputs/fastq_split/"
    shell:"""
    /group/millermrgrp3/ryan3/sneks/rabo_snakemake/scripts/BarcodeSplit_RAD_PE.2019.pl {input} GGACAAGCTATGCAGG,GGAAACATCGTGCAGG,GGACATTGGCTGCAGG,GGACCACTGTTGCAGG,GGAACGTGATTGCAGG,GGCGCTGATCTGCAGG,GGCAGATCTGTGCAGG,GGATGCCTAATGCAGG,GGAACGAACGTGCAGG,GGAGTACAAGTGCAGG,GGCATCAAGTTGCAGG,GGAGTGGTCATGCAGG,GGAACAACCATGCAGG,GGAACCGAGATGCAGG,GGAACGCTTATGCAGG,GGAAGACGGATGCAGG,GGAAGGTACATGCAGG,GGACACAGAATGCAGG,GGACAGCAGATGCAGG,GGACCTCCAATGCAGG,GGACGCTCGATGCAGG,GGACGTATCATGCAGG,GGACTATGCATGCAGG,GGAGAGTCAATGCAGG,GGAGATCGCATGCAGG,GGAGCAGGAATGCAGG,GGAGTCACTATGCAGG,GGATCCTGTATGCAGG,GGATTGAGGATGCAGG,GGCAACCACATGCAGG,GGCAAGACTATGCAGG,GGCAATGGAATGCAGG,GGCACTTCGATGCAGG,GGCAGCGTTATGCAGG,GGCATACCAATGCAGG,GGCCAGTTCATGCAGG,GGCCGAAGTATGCAGG,GGCCGTGAGATGCAGG,GGCCTCCTGATGCAGG,GGCGAACTTATGCAGG,GGCGACTGGATGCAGG,GGCGCATACATGCAGG,GGCTCAATGATGCAGG,GGCTGAGCCATGCAGG,GGCTGGCATATGCAGG,GGGAATCTGATGCAGG,GGGACTAGTATGCAGG,GGGAGCTGAATGCAGG,GGGATAGACATGCAGG,GGGCCACATATGCAGG,GGGCGAGTAATGCAGG,GGGCTAACGATGCAGG,GGGCTCGGTATGCAGG,GGGGAGAACATGCAGG,GGGGTGCGAATGCAGG,GGGTACGCAATGCAGG,GGGTCGTAGATGCAGG,GGGTCTGTCATGCAGG,GGGTGTTCTATGCAGG,GGTAGGATGATGCAGG,GGTATCAGCATGCAGG,GGTCCGTCTATGCAGG,GGTCTTCACATGCAGG,GGTGAAGAGATGCAGG,GGTGGAACAATGCAGG,GGTGGCTTCATGCAGG,GGTGGTGGTATGCAGG,GGTTCACGCATGCAGG,GGACACGAGATGCAGG,GGAAGAGATCTGCAGG,GGAAGGACACTGCAGG,GGAATCCGTCTGCAGG,GGAATGTTGCTGCAGG,GGACACTGACTGCAGG,GGACAGATTCTGCAGG,GGAGATGTACTGCAGG,GGAGCACCTCTGCAGG,GGAGCCATGCTGCAGG,GGAGGCTAACTGCAGG,GGATAGCGACTGCAGG,GGACGACAAGTGCAGG,GGATTGGCTCTGCAGG,GGCAAGGAGCTGCAGG,GGCACCTTACTGCAGG,GGCCATCCTCTGCAGG,GGCCGACAACTGCAGG,GGAGTCAAGCTGCAGG,GGCCTCTATCTGCAGG,GGCGACACACTGCAGG,GGCGGATTGCTGCAGG,GGCTAAGGTCTGCAGG,GGGAACAGGCTGCAGG,GGGACAGTGCTGCAGG,GGGAGTTAGCTGCAGG,GGGATGAATCTGCAGG,GGGCCAAGACTGCAGG {params.outdir}{wildcards.lane}_{wildcards.plate}
    """

# rule to align and combine
rule align_fastq:
    input: 
        fq = expand("outputs/fastq_split/{{lane}}_{{plate}}_R{read}_{{sample}}.fastq", read = READS),
	ref = "/home/rapeek/projects/SEQS/final_contigs_300.fa"
    output: "outputs/bams/{lane}_{plate}_{sample}.sort.bam"
    conda: "envs/samtools_bwa.yml"
    threads: 4
    resources:
        mem_mb=4000,
	#tmpdir=TMPDIR,
        time=2880
    #benchmark: "benchmarks/align_fastq_{lane}_{plate}_{sample}.tsv"
    shell:"""
	bwa mem -t {threads} {input.ref} {input.fq} | samtools view --threads {threads} -Sb - | samtools sort --threads {threads} - -o {output}
	"""

rule filter_bams:
    input: "outputs/bams/{lane}_{plate}_{sample}.sort.bam"
    output: "outputs/bams/{lane}_{plate}_{sample}.sort.flt.bam"
    conda: "envs/samtools_bwa.yml"
    threads: 4
    resources:
        mem_mb=4000,
	#tmpdir=TMPDIR,
        time=2880
    #benchmark: "benchmarks/filter_bams_{lane}_{plate}_{sample}.tsv"
    shell:"""
        samtools view --threads {threads} -f 0x2 -b {input} | samtools rmdup - {output}
        """

rule index_bams:
    input: "outputs/bams/{lane}_{plate}_{sample}.sort.flt.bam"
    output: "outputs/bams/{lane}_{plate}_{sample}.sort.flt.bam.bai"
    conda: "envs/samtools_bwa.yml"
    threads: 4
    resources:
        mem_mb=2000,
        time=2880
    shell:"""
        samtools index {input}
	"""

rule bam_stats:
    input: "outputs/bams/{lane}_{plate}_{sample}.sort.flt.bam"
    output: "outputs/stats/{lane}_{plate}_{sample}.sort.flt.bam.stats"
    threads: 1
    conda: "envs/samtools_bwa.yml"
    shell:"""
        samtools stats --threads {threads} {input} | grep ^SN | cut -f 2-4 > {output}
	"""

rule bam_depth:
    input: "outputs/bams/{lane}_{plate}_{sample}.sort.flt.bam"
    output: "outputs/stats/{lane}_{plate}_{sample}.depth"
    params:
        sampname="{lane}_{plate}_{sample}"
    threads: 2
    conda: "envs/samtools_bwa.yml"
    shell:"""
    	samtools depth {input} | awk '{{sum+=$3}} END {{if (NR > 0) print "{input}", sum/NR}}' > {output}
	"""

#rule make_bamlist:
#    input: expand("outputs/bams/{{lane}}_{plate}_{sample}.sort.flt.bam", plate = PLATES, sample = SAMPLES)
#    output: "outputs/bamlists/{lane}_all.bamlist"
#    threads: 1
#   shell:"""
#        ls {input} > {output}
#	"""

#rule make_pca:
#    input: 
#        bamlist = "outputs/bamlists/{lane}_all.bamlist",
#        ref = "/home/rapeek/projects/SEQS/final_contigs_300.fa", # put in config file
#        bait_length = "bait_lengths.txt" # put in config file, add copy in github
#    output: "outputs/pca/{lane}_pca_all.covMat"
#    threads: 16
    #conda: "envs/angsd.yml"
#    params: 
#        minInd = lambda wildcards, input: round(len(open(input.bamlist).readlines( ))/5),
#	covMat = lambda wildcards: "outputs/pca/" + wildcards.lane + "_pca_all"
 #   resources:
 #       time=1080,
#	mem_mb=lambda wildcards, attempt: attempt *8000
 #   shell:"""
 #       angsd -bam {input.bamlist} -out {params.covMat} -doIBS 1 -doCounts 1 -doMajorMinor 1 -minFreq 0.05 -maxMis {params.minInd} -minMapQ 30 -minQ 20 -SNP_pval 1e-6 -makeMatrix 1 -doCov 1 -GL 1 -doMaf 1 -nThreads {threads} -ref {input.ref} -sites {input.bait_length}
 #       """

# to add:
# sfs
# thetas
# admixture
# fst


