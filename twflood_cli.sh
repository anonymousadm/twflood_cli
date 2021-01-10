#! /bin/bash
. init.conf

cat targets.list | while read _TARGET;
do	
	_TWROBOTARRAY=($(twurl accounts | sed  -n '/^[0-9a-zA-Z]/p'))
	_RANDOM_LINE=`shuf -i 0-$((${#_TWROBOTARRAY[@]}-1)) -n 1`
	_TWROBOT=${_TWROBOTARRAY[$_RANDOM_LINE]}
	twurl set default $_TWROBOT
	twurl accounts
	_ERROR=`twurl /1.1/statuses/user_timeline.json?screen_name=$_TARGET | jq .errors[].code`
	if [[ $_ERROR -eq "326" ]]; then
		echo $(date +%Y%m%d%H%M) $_TWROBOT "this account is temporarily locked. Please log in to https://twitter.com to unlock your account." >> output.log;
	else
		until [[ $_ERROR -ne "136" ]]; do
			echo $(date +%Y%m%d%H%M) $_TWROBOT "Maybe blocked by " $_TARGET >> output.log
			_TWROBOTARRAY=($(twurl accounts | sed  -n '/^[0-9a-zA-Z]/p'))
			_RANDOM_LINE=`shuf -i 0-$((${#_TWROBOTARRAY[@]}-1)) -n 1`
			_TWROBOT=${_TWROBOTARRAY[$_RANDOM_LINE]}
			#_TWROBOTKEYNUM=`twurl accounts | sed  -n '/^'$_TWROBOT'/,/^[0-9a-zA-Z]/p' | sed -n '/\s\s*/p' | wc -l`
			#_RANDOM_LINE=`shuf -i 1-$_TWROBOTKEYNUM -n 1`
			#_TWROBOTKEY=`twurl accounts | sed  -n '/^'$_TWROBOT'/,/^[0-9a-zA-Z]/p' | sed -n '/\s\s*/p' | sed -n "$_RANDOM_LINE"p | sed 's/\s//g'`
			#twurl set default $_TWROBOT $_TWROBOTKEY
			twurl set default $_TWROBOT
			twurl accounts
			_ERROR=`twurl /1.1/statuses/user_timeline.json?screen_name=$_TARGET | jq .errors[].code`;
		done
		_TWEETIDARRAY=($(twurl /1.1/statuses/user_timeline.json?screen_name=$_TARGET | jq .[].id_str | sed 's/"//g'))
		_RANDOM_LINE=`shuf -i 0-$((${#_TWEETIDARRAY[@]}-1)) -n 1`
		_TARGET_TWEETID=${_TWEETIDARRAY[$_RANDOM_LINE]}
		
		_MEDIA_FILENUM=`ls -la $_PICFOLDER | awk '{print $9}' | sed '/^$/d' | sed '/^\./d' | wc -l`
		_RANDOM_LINE=`shuf -i 1-$_MEDIA_FILENUM -n 1`
		_MEDIA_FILE=`ls -la $_PICFOLDER | awk '{print $9}' | sed '/^$/d' | sed '/^\./d' | sed -n "$_RANDOM_LINE"p`
	
		_TWEETSNUM=`cat Tweets.list | wc -l`
		_RANDOM_LINE=`shuf -i 1-5 -n 1`
		_HASH_TAGNUM=($(shuf -i 1-$_TWEETSNUM -n $_RANDOM_LINE))
		_HASH_TAG_SUM=""
		for (( i=0 ; i<"$_RANDOM_LINE" ; i++ ));
		do
			_HASH_TAG=`cat Tweets.list | sed -n "${_HASH_TAGNUM[i]}"p`
			_HASH_TAG_SUM+=$_HASH_TAG;
		done
		_SIZE=`ls -l $_PICFOLDER"/"$_MEDIA_FILE | awk '{print $5}'`
		_MEDIA_ID_STRING=`twurl -H upload.twitter.com "/1.1/media/upload.json" -d "command=INIT&media_type=image/jpg&total_bytes=$_SIZE" | jq .media_id_string | sed 's/"//g'`
		twurl -H upload.twitter.com "/1.1/media/upload.json" -d "command=APPEND&media_id=$_MEDIA_ID_STRING&segment_index=0" --file $_PICFOLDER"/"$_MEDIA_FILE --file-field "media" | jq
		twurl -H upload.twitter.com "/1.1/media/upload.json" -d "command=FINALIZE&media_id=$_MEDIA_ID_STRING" | jq
		twurl -X POST -H api.twitter.com "/1.1/statuses/update.json?status=@$_TARGET$_HASH_TAG_SUM &in_reply_to_status_id=$_TARGET_TWEETID&media_ids=$_MEDIA_ID_STRING" | jq
		echo $(date +%Y%m%d%H%M) $_TWROBOT "reply https://twitter.com/"$_TARGET"/status/"$_TARGET_TWEETID "successful" >> output.log;
		#sleep 78;
	fi;
done
