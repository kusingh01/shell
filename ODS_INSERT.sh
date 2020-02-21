#!/bin/bash
#-----------------------------------------------------------------------------
#
# Developer - Kuldeep
# Description - This script will creat a row in Oracle table
#               ODS_JOB_DETAIL_INFO.
# Add Validation for all predeccors key in DB.
# Target Table validation - Use "It is used to load table $Target_Table"
# If inputs are not correct , prompt for renter
#-----------------------------------------------------------------------------

clear
HORIZONTALLINE="--------------------------------------------------------------"
flag=0
Result=98
Sequence=99

export RED='\033[0;31m'
export NC='\033[0m'
export YELLOW='\033[1;33m'
export LG='\033[1;32m'
export CYAN='\033[0;36m'



get_seq()
{
TABLENAME=$1
echo "Initial value of Sequence variable is - ${Sequence}"

kSeq=`sqlplus -s odidev/odidev@indlin2447:1521/CIDWH <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF 
SELECT TRIM(${TABLENAME}.nextval) from dual; 
EXIT; 
EOF` 
export Sequence=$kSeq 
echo "Sequence generated is ${Sequence}"
}


function get_pred_info()
{
#echo "Calling get_pred_info"
llResult=`sqlplus -s odidev/odidev@indlin2447:1521/CIDWH <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT batch_key || '-' || job_key || '-' || job_program_name from ODS_JOB_DETAIL_INFO where job_key = $1 and BATCH_KEY = '$2';
EXIT;
EOF`

#echo "llResult is - ${llResult}"
export PResult=$llResult

}


function sqlQuery()
{
echo "Result is - ${Result}"
lResult=`sqlplus -s odidev/odidev@indlin2447:1521/CIDWH <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT job_key from ODS_JOB_DETAIL_INFO where job_key = $1 and BATCH_KEY = '$2' and rownum = 1;
EXIT;
EOF` 

kstatus=$?
echo "$kstatus"
export Result=$lResult
echo "Result is 2-${Result}"
}

function sqlQuery1()
{
echo "Result is - ${Result}"
lResult=`sqlplus -s odidev/odidev@indlin2447:1521/CIDWH <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT TABLE_NAME from VID_TABLE_LIST where TABLE_NAME = '$1' and rownum = 1;
EXIT;
EOF`

kstatus=$?
echo "$kstatus"
export Result1=$lResult
echo "Result is 2-${Result1}"
}


get_input()
{
echo $HORIZONTALLINE
echo "This script will create a new record in table ODS_JOB_DETAIL_INFO"
echo "Please provide the required values for creating the row"

echo -e "\n"
echo "Mandatory Field - BATCH_KEY"
echo -e "${CYAN}Valid BATCH_KEY are - ADH / NRT / VID / DLY / MTH / REF / OTL${NC}"

while [ $flag -eq 0 ]
do
   echo "Enter valid BATCH_KEY"
   read BATCH_KEY

   case $BATCH_KEY in

       ADH|NRT|VID|DLY|MTH|REF|OTL)
          echo "${BATCH_KEY} is valid BATCH_KEY";
          export BATCH_KEY
          flag=`expr $flag + 1`
       ;;

       *)
           echo -e "\n ${RED}${BATCH_KEY} is invalid BATCH_KEY"
           echo -e "\n Please enter valid BATCH_KEY again.${NC}"
        ;;
   esac
done

clear
echo "Mandatory Field - JOB_PROGRAM_NAME"
echo  "Examples :-"
echo -e "${CYAN}JB_ASSPROD_F_SUBR_ACTIVE_OFFER_D"
echo    "vid_language_pt.bteq.ctl"
echo -e "billingarrangementstatus ${NC}"
echo "Enter JOB_PROGRAM_NAME"

flag=0
while [ $flag -eq 0 ]
  do
  read JOB_PROGRAM_NAME

  if [ -z "$JOB_PROGRAM_NAME"  ];
    then
      echo -e "${RED} JOB_PROGRAM_NAME is mandatory ${NC}"
      echo "Enter JOB_PROGRAM_NAME"
      flag=0
  else
          flag=`expr $flag + 1`
  fi
done
export JOB_PROGRAM_NAME

export SUCCESSOR_KEY=999999

clear
flag=0
fflag=0
firsttime=0
predinfo=""
while [ $flag -eq 0 ]
do
  touch /home/etluser/KDS/temp.txt
  rm -f /home/etluser/KDS/temp.txt

  echo "Mandatory Field - PREDECESSOR_KEY"
  echo -e "${YELLOW} Enter PREDECESSOR_KEY all of which must exists.${NC}"
  echo  "Examples :-"
  echo -e "${CYAN}910000,111001,111002"
  echo -e "111001${NC}"
  echo -e "\n ${RED}"
  echo -e "FOR REF ENSURE TO KEEP 691001(FUNNEL JOB) ALSO IN PREDECESSOR KEY ${NC}"
  read PREDECESSOR_KEY

  for singleKey in $(echo $PREDECESSOR_KEY | sed "s/,/ /g")
  do
    fflag=0
    sqlQuery $singleKey $BATCH_KEY
    echo "Result returned is $Result"

    #If returened value not equals passed value, it means singleKey does not exists.return with error"
    if [ -z "$Result"  ];
    then
       echo -e "${RED}One of the KEY - ${singleKey} doesn't exists. You should enter valid PREDECESSOR_KEY ${NC}"
       #exit from for loop
       rm -f /home/etluser/KDS/temp.txt
	   fflag=0
       break
    elif [ $Result -eq $singleKey ];
    then
       echo "${singleKey} key is valid."
       fflag=1

       get_pred_info $singleKey $BATCH_KEY
       echo $PResult >> /home/etluser/KDS/temp.txt
       echo -e "\n"  >> /home/etluser/KDS/temp.txt

    else 
       echo -e "${RED}There is some issue with SQL. Please fix ${NC}"
       exit 5
    fi
  done

  if [ $fflag -eq 1 ];
  then
   export PREDECESSOR_KEY
   flag=`expr $flag + 1` 
#   echo "flag at the end of while loop is ${flag}" 
  fi 
done 


clear
echo "Mandatory Field - JOB_TYPE"
echo -e "${CYAN}Valid Values are - BTEQ / FWRK / HDFS / ODI / REFBL / REFCL / REFED / REFHL / REFKL / REFRR / REFST / SKIP${NC}"
echo "Enter JOB_TYPE"
read JOB_TYPE
export JOB_TYPE

#clear
#echo "Optional Field - RUN_MODE"
#echo ""
#echo "Enter RUN_MODE"
#read RUN_MODE
#export RUN_MODE

clear
echo "Optional Field - SOURCE_TBL"
echo "Mandatory for ???"
echo "Enter SOURCE_TBL"
read SOURCE_TBL
export SOURCE_TBL

#clear
#echo "Optional Field - STG_TBL_NM"
#echo "Mandatory for ODI jobs having STG tables"
#echo "Enter STG_TBL_NM"
#read STG_TBL_NM
#export STG_TBL_NM


clear
echo "Mandatory Field - TGT_TBL_NM"
echo -e "${YELLOW} Enter Target table name of this script/Job." 
echo -e "Example - For STG put STG table." 
echo -e "For merge bteq put target table name ${NC}"
flag=0
while [ $flag -eq 0 ]
  do
  read TGT_TBL_NM

  if [ -z "$TGT_TBL_NM"  ];
    then
      echo -e "${RED}TARGET TABLE Name is mandatory ${NC}"
      echo "Enter TGT_TBL_NM :"
      flag=0
  else
	  flag=`expr $flag + 1`
  fi  
done
export TGT_TBL_NM



########################################################
#Get Final Target Table name that is present in the model
########################################################

clear
echo "Mandatory Field - FINAL TARGET TABLE NAME"
echo "Enter actual TARGET table of this script/Job"
echo "Example - For Both STG and Merge, put actual final table"

flag=0
while [ $flag -eq 0 ]
  do
  read FIN_TGT_TBL

  if [ -z "$FIN_TGT_TBL"  ];
    then
      echo -e "${RED}TARGET TABLE Name is mandatory ${NC}"
      echo "Enter actual TARGET table of this script/Job :"
      flag=0
  else
    sqlQuery1 $FIN_TGT_TBL
    echo "Result1 is - ${Result1}"
      
    if [[ -z $Result1 ]];
    then
      echo "Input FINAL TARGET TABLE NAME - ${FIN_TGT_TBL} is INVALID"
      echo "Enter actual TARGET table of this script/Job"
      flag=0
    else
      echo "Input Final Table is VALID"
          flag=`expr $flag + 1`
    fi
  fi
done
export FIN_TGT_TBL


export JOB_DESC="Job to insert data in table ${TGT_TBL_NM}"

clear
#echo "Optional Field"
#echo "PARTITION_COL"
#echo "Enter PARTITION_COL"
#read PARTITION_COL
#export PARTITION_COL

clear
#echo "Optional Field"
#echo "NUM_OF_PARTITION"
#echo "Enter NUM_OF_PARTITION"
#read NUM_OF_PARTITION
#export NUM_OF_PARTITION

#clear
#echo "Optional Field"
#echo "TGT_MOD_TABLE_DETAIL"
#echo "Enter TGT_MOD_TABLE_DETAIL"
#read TGT_MOD_TABLE_DETAIL
#export TGT_MOD_TABLE_DETAIL

#echo "Mandatory Field"
#echo "CRITICAL_FLAG - Y/N - Yes/No - "
#echo "Enter CRITICAL_FLAG"
#read CRITICAL_FLAG
export CRITICAL_FLAG='Y'

#echo "Mandatory Field"
#echo "JOB_PRIORITY - Default value to be entered is 10"
#echo "Enter JOB_PRIORITY"
#read JOB_PRIORITY
export JOB_PRIORITY=10

echo "Mandatory Field - JOB_PARAMETERS"
echo -e "JOB_PARAMETERS - ${YELLOW}Mandatory for ODI jobs. For other jobs it is not required ${NC}"
echo -e "Examples - ${CYAN}BATCH_ID|END_TIME|START_TIME|VAR_LANDING_VW ${NC}"
echo "Enter JOB_PARAMETERS"
read JOB_PARAMETERS

clear
#--------------------------------
# Generating JOB_KEY
#--------------------------------

digit_1=0
digit_2=0
digit_3=0
case $BATCH_KEY in

  ADH)
    digit_1=1
    half_no=$digit_1
        echo "Please select correct Option"
        echo -e "${CYAN} 1. Unix Script"
        echo -e " 2. Dummy or Funnel${NC}"
        echo "Enter Option - "

  # Getting correct option from user
    flag=0
    while [ $flag -eq 0 ]
    do
      read OPTN
      case $OPTN in
      1|2) flag=`expr $flag + 1`
        ;;
      *)
        echo -e "${RED}Invalid Option\n"
        echo -e "Please select correct Option for BATCH_KEY - ADH${NC}"
        echo -e "${CYAN} 1. Unix Script"
        echo -e " 2. Dummy or Funnel${NC}"
        echo "Enter Option - "
        ;;
      esac
    done

        case $OPTN in
           1)
         echo "ADH Unix Script- 110XXX"

         digit_2=1
         half_no+=$digit_2
         digit_3=0
         half_no+=$digit_3
         echo "half_no is - ${half_no}"


         SEQ_KEY="OJDI_ADH_1_SEQ"
         get_seq $SEQ_KEY
         half_no+=$Sequence
         echo "Final JOB_KEY is - ${half_no}"
         export JOB_KEY=$half_no
         ;;
       2)
          echo "ADH DUMMY or FUNNEL - 191XXX"
          digit_2=9
          half_no+=$digit_2
          digit_3=1
          half_no+=$digit_3
  
         SEQ_KEY="OJDI_ADH_2_SEQ"
         get_seq $SEQ_KEY
         half_no+=$Sequence
         echo "Final JOB_KEY is - ${half_no}"
         export JOB_KEY=$half_no
         ;;
    esac

  # End of Option ADH
        ;;



  NRT)
        digit_1=2
        half_no=$digit_1
        echo ""
        echo "Please select correct Option"
        echo -e "${CYAN} 1. PT/LKP 210XXX"
        echo " 2. DIM LND->STG 221XXX"
        echo " 3. DIM ERR->STG 222XXX"
        echo " 4. DIM STG->VID 229XXX"
        echo " 5. FACT LND->STG 231XXX"
        echo " 6. FACT ERR->STG 232XXX"
        echo " 7. FACT STG->VID 239XXX"
        echo " 8. UNIX SCRIPT 250XXX"
        echo -e " 9. DUMMY OR FUNNEL 291XXX ${NC}"
        echo "Enter Option - "

        flag=0
        while [ $flag -eq 0 ]
        do
         read OPTN
         case $OPTN in
          1|2|3|4|5|6|7|8|9) 
          flag=`expr $flag + 1`
          ;;
  
          *)
            echo -e "${RED}Invalid Option"
            echo -e "Please select correct Option for BATCH_KEY - NRT${NC}"
            echo -e "${CYAN} 1. PT/LKP 210XXX"
            echo " 2. DIM LND->STG 221XXX"
            echo " 3. DIM ERR->STG 222XXX"
            echo " 4. DIM STG->VID 229XXX"
            echo " 5. FACT LND->STG 231XXX"
            echo " 6. FACT ERR->STG 232XXX"
            echo " 7. FACT STG->VID 239XXX"
            echo " 8. UNIX SCRIPT 250XXX"
            echo -e " 9. DUMMY OR FUNNEL 291XXX${NC}"
            echo "Enter Option - "
            ;;
         esac
        done


        case $OPTN in
          1)
            echo "Your option is PT/LKP 210XXX"
            digit_2=1
            half_no+=$digit_2
            digit_3=0
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_1_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
            ;;
          2)
            echo " DIM LND->STG 221XXX "
            digit_2=2
            half_no+=$digit_2
            digit_3=1
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_2_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no			
            ;;
          3)
            echo " DIM ERR->STG 222XXX "
            digit_2=2
            half_no+=$digit_2
            digit_3=2
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_3_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
            ;;
          4)
            echo " DIM STG->VID 229XXX "
            digit_2=2
            half_no+=$digit_2
            digit_3=9
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_4_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
            ;;
          5)
            echo " FACT LND->STG 231XXX "
            digit_2=3
            half_no+=$digit_2
            digit_3=1
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_5_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
           ;;
          6)
            echo " FACT ERR->STG 232XXX "
            digit_2=3
            half_no+=$digit_2
            digit_3=2
            half_no+=$digit_3

            SEQ_KEY="OJDI_NRT_6_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
           ;;
          7)
            echo " FACT STG->ODS 239XXX "
            digit_2=3
            half_no+=$digit_2
            digit_3=9
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_7_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
            ;;
          8)
            echo " UNIX SCRIPT 250XXX "
            digit_2=5
            half_no+=$digit_2
            digit_3=0
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_8_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
            ;;
          9)
            echo "DUMMY OR FUNNEL 291XXX "
            digit_2=9
            half_no+=$digit_2          
            digit_3=1
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_NRT_9_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
          ;;
          *)
         echo "Sorry, Option appears Wrong"
         ;;
       esac
	   
# End of Option NRT
  ;;




  VID)
        digit_1=3
        half_no=$digit_1
        echo ""
        echo "Please select correct Option"
        echo -e "${CYAN} 1. PT/LKP 310XXX"
        echo " 2. DIM LND->STG 321XXX"
        echo " 3. DIM ERR->STG 322XXX"
        echo " 4. DIM STG->VID 329XXX"
        echo " 5. FACT LND->STG 331XXX"
        echo " 6. FACT ERR->STG 332XXX"
        echo " 7. FACT STG->VID 339XXX"
        echo " 8. UNIX SCRIPT 355XXX"
        echo -e " 9. DUMMY OR FUNNEL 391XXX${NC}"
        echo "Enter Option - "

        flag=0
    while [ $flag -eq 0 ]
    do
    read OPTN
    case $OPTN in
      1|2|3|4|5|6|7|8|9) flag=`expr $flag + 1`
        ;;
      *)
        echo "Invalid Option"
        echo "Please select correct Option for BATCH_KEY - NRT"
        echo -e "${CYAN} 1. PT/LKP 310XXX"
        echo " 2. DIM LND->STG 321XXX"
        echo " 3. DIM ERR->STG 322XXX"
        echo " 4. DIM STG->VID 329XXX"
        echo " 5. FACT LND->STG 331XXX"
        echo " 6. FACT ERR->STG 332XXX"
        echo " 7. FACT STG->VID 339XXX"
        echo " 8. UNIX SCRIPT 355XXX"
        echo -e " 9. DUMMY OR FUNNEL 391XXX${NC}"
        echo "Enter Option - "
        ;;
     esac
    done


          case $OPTN in
           1)
         echo "Your option is PT/LKP 310XXX"
         digit_2=1
            half_no+=$digit_2
         digit_3=0
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_VID_1_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       2)
          echo " DIM LND->STG 321XXX "
          digit_2=2
            half_no+=$digit_2
          digit_3=1
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_2_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       3)
          echo " DIM ERR->STG 322XXX "
          digit_2=2
            half_no+=$digit_2
          digit_3=2
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_3_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       4)
          echo " DIM STG->VID 329XXX "
          digit_2=2
            half_no+=$digit_2
          digit_3=9
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_4_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       5)
          echo " FACT LND->STG 331XXX "
          digit_2=3
            half_no+=$digit_2
          digit_3=1
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_5_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       6)
          echo " FACT ERR->STG 332XXX "
          digit_2=3
            half_no+=$digit_2
          digit_3=2
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_6_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       7)
          echo " FACT STG->VID 339XXX "
          digit_2=3
            half_no+=$digit_2          
		  digit_3=9
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_7_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       8)
          echo " UNIX SCRIPT 355XXX "
          digit_2=5
            half_no+=$digit_2
          digit_3=5
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_8_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       9)
          echo "DUMMY OR FUNNEL 391XXX "
          digit_2=9
            half_no+=$digit_2          
		  digit_3=1
            half_no+=$digit_3		  
  
            SEQ_KEY="OJDI_VID_9_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       esac
  # End of Option VID
        ;;




  DLY)
        digit_1=4
        half_no=$digit_1
        echo ""
        echo "Please select correct Option"
        echo -e "${CYAN} 1. PT/LKP 410XXX"
        echo " 2. DIM LND->STG 421XXX"
        echo " 3. DIM ERR->STG 422XXX"
        echo " 4. DIM STG->VID 429XXX"
        echo " 5. FACT LND->STG 431XXX"
        echo " 6. FACT ERR->STG 432XXX"
        echo " 7. FACT STG->VID 439XXX"
        echo " 8. UNIX SCRIPT 455XXX"
        echo -e " 9. DUMMY OR FUNNEL 491XXX${NC}"
        echo "Enter Option - "

        flag=0
    while [ $flag -eq 0 ]
    do
    read OPTN
    case $OPTN in
      1|2|3|4|5|6|7|8|9) flag=`expr $flag + 1`
        ;;
      *)
        echo "Invalid Option"
        echo "Please select correct Option for BATCH_KEY - NRT"
        echo -e "${CYAN} 1. PT/LKP 410XXX"
        echo " 2. DIM LND->STG 421XXX"
        echo " 3. DIM ERR->STG 422XXX"
        echo " 4. DIM STG->ODS 429XXX"
        echo " 5. FACT LND->STG 431XXX"
        echo " 6. FACT ERR->STG 432XXX"
        echo " 7. FACT STG->ODS 439XXX"
        echo " 8. UNIX SCRIPT 455XXX"
        echo -e " 9. DUMMY OR FUNNEL 491XXX${NC}"
        echo "Enter Option - "
        ;;
     esac
    done


          case $OPTN in
           1)
         echo "Your option is PT/LKP 410XXX"
         digit_2=1
            half_no+=$digit_2 
         digit_3=0
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_1_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       2)
          echo " DIM LND->STG 421XXX "
          digit_2=2
            half_no+=$digit_2 
          digit_3=1
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_2_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       3)
          echo " DIM ERR->STG 222XXX "
          digit_2=2
            half_no+=$digit_2 
          digit_3=2
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_3_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       4)
          echo " DIM STG->ODS 229XXX "
          digit_2=2
            half_no+=$digit_2 
          digit_3=9
            half_no+=$digit_3         
  
            SEQ_KEY="OJDI_DLY_4_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
		 ;;
       5)
          echo " FACT LND->STG 231XXX "
          digit_2=3
            half_no+=$digit_2 
          digit_3=1
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_5_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       6)
          echo " FACT ERR->STG 232XXX "
          digit_2=3
            half_no+=$digit_2 
          digit_3=2
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_6_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no
         ;;
       7)
          echo " FACT STG->ODS 239XXX "
            digit_2=3
            half_no+=$digit_2 
            digit_3=9
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_7_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       8)
          echo " UNIX SCRIPT 455XXX "
          digit_2=5
            half_no+=$digit_2 
          digit_3=5
            half_no+=$digit_3
  
            SEQ_KEY="OJDI_DLY_8_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       9)
          echo "DUMMY OR FUNNEL 491XXX "
          digit_2=9
            half_no+=$digit_2 
          digit_3=1
            half_no+=$digit_3         
  
            SEQ_KEY="OJDI_DLY_9_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
		 ;;
          esac
  # End of Option DLY
        ;;




  MTH)
        digit_1=5
        half_no=$digit_1
        echo ""
        echo "Please select correct Option"
        echo -e "${CYAN} 1. PT/LKP 510XXX"
        echo " 2. DIM LND->STG 521XXX"
        echo " 3. DIM ERR->STG 522XXX"
        echo " 4. DIM STG->VID 529XXX"
        echo " 5. FACT LND->STG 531XXX"
        echo " 6. FACT ERR->STG 532XXX"
        echo " 7. FACT STG->VID 539XXX"
        echo " 8. UNIX SCRIPT 555XXX"
        echo -e " 9. DUMMY OR FUNNEL 591XXX${NC}"
        echo "Enter Option - "

        flag=0
        while [ $flag -eq 0 ]
        do
        read OPTN
        case $OPTN in

          1|2|3|4|5|6|7|8|9) flag=`expr $flag + 1`
          ;;

          *)
           echo "Invalid Option"
           echo "Please select correct Option for BATCH_KEY - NRT"
           echo -e "${CYAN} 1. PT/LKP 510XXX"
           echo " 2. DIM LND->STG 521XXX"
           echo " 3. DIM ERR->STG 522XXX"
           echo " 4. DIM STG->VID 529XXX"
           echo " 5. FACT LND->STG 531XXX"
           echo " 6. FACT ERR->STG 532XXX"
           echo " 7. FACT STG->VID 539XXX"
           echo " 8. UNIX SCRIPT 555XXX"
           echo -e " 9. DUMMY OR FUNNEL 591XXX${NC}"
           echo "Enter Option - "
         ;;
        esac
        done


    case $OPTN in
       1)
         echo "Your option is PT/LKP 510XXX"
         digit_2=1
         half_no+=$digit_2
         digit_3=0
         half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_1_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       2)
          echo " DIM LND->STG 521XXX "
          digit_2=2
          half_no+=$digit_2
          digit_3=1
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_2_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       3)
          echo " DIM ERR->STG 522XXX "
          digit_2=2
          half_no+=$digit_2
          digit_3=2
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_3_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       4)
          echo " DIM STG->ODS 529XXX "
          digit_2=2
          half_no+=$digit_2
          digit_3=9
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_4_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       5)
          echo " FACT LND->STG 531XXX "
          digit_2=3
          half_no+=$digit_2
          digit_3=1
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_5_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       6)
          echo " FACT ERR->STG 532XXX "
          digit_2=3
          half_no+=$digit_2
          digit_3=2
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_6_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       7)
          echo " FACT STG->ODS 539XXX "
          digit_2=3
          half_no+=$digit_2          
		  digit_3=9
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_7_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       8)
          echo " UNIX SCRIPT 555XXX "
          digit_2=5
          half_no+=$digit_2
          digit_3=5
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_8_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       9)
          echo "DUMMY OR FUNNEL 591XXX "
          digit_2=9
          half_no+=$digit_2
          digit_3=1
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_MTH_9_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
     ;;
     esac



  # End of Option MTH
        ;;



  REF)
        echo "REF"
        digit_1=6
        half_no=$digit_1
        echo ""
        echo "Please select correct Option"
        echo -e "${CYAN} 1. PT/LKP 610XXX"
        echo " 2. DIM LND->STG 621XXX"
        echo -e " 3. DIM STG->VID 622XXX${NC}"

        echo "Enter Option - "

        flag=0
        while [ $flag -eq 0 ]
        do
        read OPTN
        case $OPTN in

          1|2|3) 
		  flag=`expr $flag + 1`
          ;;

          *)
           echo "Invalid Option"
           echo "Please select correct Option for BATCH_KEY - NRT"
           echo " 1. PT/LKP 610XXX" 
           echo " 2. DIM LND->STG 621XXX"
           echo " 3. DIM STG->VID 622XXX"
           echo "Enter Option - "
         ;;
        esac
        done

    case $OPTN in
       1)
         echo "Your option is PT/LKP 610XXX"
         digit_2=1
         half_no+=$digit_2
         digit_3=0
         half_no+=$digit_3         
  
            SEQ_KEY="OJDI_REF_1_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       2)
          echo " DIM LND->STG 621XXX "
          digit_2=2
          half_no+=$digit_2
          digit_3=1
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_REF_2_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       3)
          echo " DIM STG->VID 622XXX "
          digit_2=2
          half_no+=$digit_2
          digit_3=2
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_REF_3_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
    esac    
  # End of Option REF
        ;;



  OTL)
        echo "OTL"
        digit_1=7
        half_no=$digit_1
        echo ""
        echo "Please select correct Option"
        echo " 1. BTEQ 720XXX"
        echo " 2. ODI  710XXX"

        echo "Enter Option - "

        flag=0
        while [ $flag -eq 0 ]
        do
        read OPTN
        case $OPTN in

          1|2) 
		  flag=`expr $flag + 1`
          ;;

          *)
           echo "Invalid Option"
           echo "Please select correct Option for BATCH_KEY - NRT"
           echo " 1. BTEQ 720XXX"
           echo " 2. ODI  710XXX"

           echo "Enter Option - "
         ;;
        esac
        done

    case $OPTN in
       1)
         echo "Your option is BTEQ 720XXX"
         digit_2=2
         half_no+=$digit_2
         digit_3=0
         half_no+=$digit_3         
  
            SEQ_KEY="OJDI_OTL_1_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
       2)
          echo "ODI  710XXX"
          digit_2=1
          half_no+=$digit_2
          digit_3=0
          half_no+=$digit_3         
  
            SEQ_KEY="OJDI_OTL_2_SEQ"
            get_seq $SEQ_KEY
            half_no+=$Sequence
            export JOB_KEY=$half_no 
         ;;
    esac    		
  # End of Option OTL

        ;;


  *)
        echo "Sorry, I don't understand"
        ;;
esac

clear

flag=0
echo "Enter Your Amdocs EMAIL-ID: "
while [ $flag -eq 0 ]
 do
  read USR_EMAIL
  if [ -z "$USR_EMAIL"  ];
    then
      echo -e "${RED} EMAIL-ID is mandatory ${NC}"
      echo "Enter Your EMAIL-ID"
      flag=0
  else
          flag=`expr $flag + 1`
  fi
done
export DEV_OWNER_EMAIL=$USR_EMAIL


echo "End of get_input function"
}

get_input


oflag=0
while [ $oflag -eq 0 ]
 do
echo "Below values will be inserted in DB"
echo -e "\n"

echo -e "${LG}BATCH_KEY             is ${BATCH_KEY}"
echo "JOB_KEY               is ${JOB_KEY}"
echo "JOB_PROGRAM_NAME      is ${JOB_PROGRAM_NAME}"
echo "JOB_DESC              is ${JOB_DESC}"
echo "SUCCESSOR_KEY         is ${SUCCESSOR_KEY}"
echo "JOB_KEY               is ${JOB_KEY}"
echo "JOB_TYPE              is ${JOB_TYPE}"
#echo "RUN_MODE              is ${RUN_MODE}"
echo "PREDECESSOR_KEY       is ${PREDECESSOR_KEY}"
#echo "SOURCE_TBL            is ${SOURCE_TBL}"
#echo "STG_TBL_NM            is ${STG_TBL_NM}"
echo "TGT_TBL_NM            is ${TGT_TBL_NM}"
#echo "PARTITION_COL         is ${PARTITION_COL}"
#echo "NUM_OF_PARTITION      is ${NUM_OF_PARTITION}"
echo "TGT_MOD_TABLE_DETAIL  is ${TGT_MOD_TABLE_DETAIL}"
echo "CRITICAL_FLAG         is ${CRITICAL_FLAG}"
echo "JOB_PRIORITY          is ${JOB_PRIORITY}"
echo -e "JOB_PARAMETERS        is ${JOB_PARAMETERS}${NC}"

echo "Use below option to confirm or reenter value again"
echo " 1. If these value are correct and can be inserted in DB"
echo " 2. Values are wrong and needs to be rentered"

read OPTN
flag=0
while [ $flag -eq 0 ]
  do

  case $OPTN in
        1|2) 
          flag=`expr $flag + 1`
          ;;
  
        *)
          echo -e "${RED}Invalid Option\n"
          echo -e "Please select correct Option ${NC}"
          echo " 1. If these value are correct and can be inserted in DB"
          echo " 2. Values are wrong and needs to be rentered"
          echo "Enter Option - "
          ;;
  esac
  done

case $OPTN in
       1)

        echo "Starting SQL Insert"

sqlplus -s odidev/odidev@indlin2447:1521/CIDWH <<EOF
INSERT INTO ODS_JOB_DETAIL_INFO (BATCH_KEY,JOB_KEY,JOB_PROGRAM_NAME,JOB_DESC,SUCCESSOR_KEY,PREDECESSOR_KEY,JOB_TYPE,RUN_MODE, SOURCE_TBL,STG_TBL_NM,TGT_TBL_NM,PARTITION_COL,NUM_OF_PARTITION,TGT_MOD_TABLE_DETAIL,CRITICAL_FLAG,JOB_PRIORITY,JOB_PARAMETERS,DEV_OWNER_EMAIL_ID)
VALUES
('$BATCH_KEY','$JOB_KEY', '$JOB_PROGRAM_NAME', '$JOB_DESC','$SUCCESSOR_KEY','$PREDECESSOR_KEY','$JOB_TYPE','$RUN_MODE', '$SOURCE_TBL','$STG_TBL_NM', '$TGT_TBL_NM', '$PARTITION_COL', '$NUM_OF_PARTITION', '$TGT_MOD_TABLE_DETAIL','$CRITICAL_FLAG', '$JOB_PRIORITY', '$JOB_PARAMETERS', '$DEV_OWNER_EMAIL'); 
commit; 
EOF

sqlplus -s odidev/odidev@indlin2447:1521/CIDWH <<EOF
INSERT INTO OJDI_DEV_INFO (DEV_OWNER_EMAIL_ID, JOB_PROGRAM_NAME, FIN_TGT_TBL_NM)
VALUES
('$DEV_OWNER_EMAIL', '$JOB_PROGRAM_NAME','$FIN_TGT_TBL' );
commit;
EOF

FileVar=`cat /home/etluser/KDS/temp.txt`


echo -e "A new records has been inserted in ODS_JOB_DETAIL_INFO with BATCH_KEY => ${BATCH_KEY} and JOB_KEY => ${JOB_KEY}  for JOB => ${JOB_PROGRAM_NAME} with JOB_TYPE => ${JOB_TYPE} \n\n Below are the predecessor key \n ${FileVar}" | mail -s "New record in ODS_JOB_DETAIL_INFO" ${DEV_OWNER_EMAIL},kusingh@amdocs.com,sangrams@amdocs.com,prashang@amdocs.com,dipalm@amdocs.com

echo "Please do not forget to add the insert statement to PERFORCE"
        
SQLQUERY="INSERT INTO ODS_JOB_DETAIL_INFO (BATCH_KEY,JOB_KEY,JOB_PROGRAM_NAME,JOB_DESC,SUCCESSOR_KEY,PREDECESSOR_KEY,JOB_TYPE,RUN_MODE, SOURCE_TBL,STG_TBL_NM,TGT_TBL_NM,PARTITION_COL,NUM_OF_PARTITION,TGT_MOD_TABLE_DETAIL,CRITICAL_FLAG,JOB_PRIORITY,JOB_PARAMETERS,DEV_OWNER_EMAIL_ID) VALUES('$BATCH_KEY','$JOB_KEY', '$JOB_PROGRAM_NAME', '$JOB_DESC','$SUCCESSOR_KEY','$PREDECESSOR_KEY','$JOB_TYPE','$RUN_MODE', '$SOURCE_TBL','$STG_TBL_NM', '$TGT_TBL_NM', '$PARTITION_COL', '$NUM_OF_PARTITION', '$TGT_MOD_TABLE_DETAIL','$CRITICAL_FLAG', '$JOB_PRIORITY', '$JOB_PARAMETERS', '$DEV_OWNER_EMAIL');"

echo "SQL Quey is - ${SQLQUERY}"
oflag=`expr $oflag + 1`

;;

    2)
     get_input
     ;;

esac
done
