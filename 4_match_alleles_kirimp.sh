#!/bin/bash
if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <vcf_input> <recode_file> <kirimp_ref>"
   echo "Matches data alleles to KIR*IMP reference using"
   echo "output from 3_make_file_match_alleles_kirimp.R"
   echo "Also updates all varIDs to chr:pos:ref:alt after"
   echo "match and trims to region of KIR*IMP panel."
   exit
fi

vcf_input=$1
recode_file=$2
kirimp_ref=$3

vcf_input_name=$(basename $vcf_input | sed 's/\.vcf.*//')

# Update alleles to match KIR*IMP reference panel
plink2 --vcf  "$vcf_input" \
   --chr chr19 \
   --ref-allele force "$recode_file" 2 1 \
   --make-pgen \
   --out temp_"$vcf_input_name"_match_kirimp

# Update varIDs to switched ref/alt and trim to same region as
# KIR*IMP reference panel
min_pos=$(tail -n +2 "$kirimp_ref" | cut -d ',' -f 2 | sort -n | head -n 1)
max_pos=$(tail -n +2 "$kirimp_ref" | cut -d ',' -f 2 | sort -n | tail -n 1)

plink2 --pfile temp_"$vcf_input_name"_match_kirimp \
   --chr chr19 --from-bp "$min_pos" --to-bp "$max_pos" \
   --set-all-var-ids @:#:\$r:\$a \
   --new-id-max-allele-len 40 \
   --recode vcf 'bgz' \
   --out "$vcf_input_name"_match_kirimp

# Convert to format for KIR*IMP
bcftools convert "$vcf_input_name"_match_kirimp.vcf.gz \
	--hapsample "$vcf_input_name"_match_kirimp
