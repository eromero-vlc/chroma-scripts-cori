
# num_args ...
# Return the number of arguments

num_args() {
	echo $#
}

# take_first ...
# Return the first argument
take_first() {
	echo ${1}
}

# Return useful variables for grouping
get_grouping_vars() {
	# Set phase groups
	phase_groups="$( get_all_phases )"

	# Set tsep groups
	if [ ${redstar_3pt} == yes ] ; then
		tsep_groups="$( for tsep in $gprop_t_seps ; do echo $tsep ; done | sort -u -n )"
		[ x${max_tseps_per_job} == x ] && max_tseps_per_job="$( num_args $tsep_groups )"
		
	else
		tsep_groups=0
		max_tseps_per_job=1
	fi
}

neg_mom() {
	echo $(( -$1 )) $(( -$2 )) $(( -$3 ))
}

neg_mom_mom() {
	echo $(( -$1 )) $(( -$2 )) $(( -$3 )) $(( -$4 )) $(( -$5 )) $(( -$6 ))
}

# mom_word momx0 momy0 momz0 [momx1 momy1 momz1]
# Return a single word representing a momentum (transfer)

mom_word() {
	[ $# == 3 ] && echo ${1}_${2}_${3}
	[ $# == 6 ] && echo ${1}_${2}_${3}_${4}_${5}_${6}
	[ $# == 7 ] && echo ${1}_${2}_${3}_${4}_${5}_${6}_${7}
	[ $# == 9 ] && echo ${1}_${2}_${3}_${4}_${5}_${6}_${7}_${8}_${9}
}

is_canonical() {
	if [ $1 -ne 0 ] ; then
		[ $1 -gt 0 ] && return 0
	elif [ $2 -ne 0 ] ; then
		[ $2 -gt 0 ] && return 0
	elif [ $3 -ne 0 -o $# -eq 3 ] ; then
		[ $3 -ge 0 ] && return 0
	elif [ $4 -ne 0 ] ; then
		[ $4 -gt 0 ] && return 0
	elif [ $5 -ne 0 ] ; then
		[ $5 -gt 0 ] && return 0
	elif [ $6 -ne 0 ] ; then
		[ $6 -ge 0 ] && return 0
	fi
	return 1
}

make_canonical() {
	if is_canonical $( mom_auto_phase $@ ) ; then
		echo $@
	else
		neg_mom_mom $@
	fi
}

mom_auto_phase() {
	if [ ${redstar_auto_phasing_sign} != yes ] ; then
	for i in ${@//-/}; do
		echo -n $(( i >= 4 ? redstar_auto_phasing_4plus : ( i == 3 ? redstar_auto_phasing_3 : 0) )) ""
	done
	else
		for i in ${@}; do
			echo -n $(( i <= -4 ? -redstar_auto_phasing_4plus :
					( i == -3 ? -redstar_auto_phasing_3 :
					( i <= 2 ? 0 :
					( i == 3 ? redstar_auto_phasing_3 : redstar_auto_phasing_4plus))) )) ""
		done
	fi
	echo
}

momtype() {
	for i in $@; do echo $i; done | tr -d '-' | sort -nr | tr '\n' ' '
}

# mom_fly momx0 momy0 momz0 [momx1 momy1 momz1] 
# Return a canonical direction of mom0 - mom1 and the phasing

mom_fly() {
	if [ $# == 3 ]; then
		echo $1 $2 $3
	else
		echo $(( $1-$4 )) $(( $2-$5 )) $(( $3-$6 ))
	fi
}

# Return a list of correlation functions as follows:
# phased_snk phased_src mom_snk mom_src [2pt|3pt]

get_all_corr() {
	[ ${redstar_3pt} == yes ] && echo "$redstar_3pt_snkmom_srcmom" | while read momij; do
		echo $( mom_auto_phase $momij ) $momij 3pt
	done | sort -u
	[ ${redstar_2pt} == yes ] && echo "$redstar_2pt_moms" | while read momij; do
		echo $( mom_auto_phase $momij ) $momij 2pt
	done | sort -u
}

get_phase_from_corr_line() {
	echo ${1} ${2} ${3} ${4} ${5} ${6}
}

get_mom_from_corr_line() {
	echo ${7} ${8} ${9} ${10} ${11} ${12}
}

get_type_from_corr_line() {
	echo ${13}
}

get_all_phases() {
	local l
	get_all_corr | while read l ; do
		[ $(num_args $l ) -gt 0 ] && echo $( mom_word $( get_phase_from_corr_line $l ) )
	done | sort -u
}

get_fly_moms() {
	local l
	get_all_corr | while read l ; do
		for phase in $@ ; do
			if [ $(num_args $l ) -gt 0 -a $( mom_word $( get_phase_from_corr_line $l ) ) == $phase ] ; then
				 echo $( mom_word $( mom_fly $( get_mom_from_corr_line $l ) ) )
			fi
		done
	done | sort -u
}

mom_word_esp() {
	echo ${1}~${2}~${3}~${4}~${5}~${6}~${7}
}

get_corr_lines() {
	local l
	local m
	get_all_corr | while read l ; do
		[ $(num_args $l ) == 0 ] && continue
		local this_mom="$( mom_word $( mom_fly $( get_mom_from_corr_line $l ) ) )"
		for m in $@ ; do
			if [ $this_mom == $m ] ; then
				if [ $( get_type_from_corr_line $l) == 2pt ] ; then
					mom_word_esp $( get_mom_from_corr_line $l ) 2pt
				else
					for ins in $redstar_insertion_operators ; do
						mom_word_esp $( get_mom_from_corr_line $l ) $ins
					done
				fi
				break
			fi
		done
	done
}

get_sink() {
	echo $1 $2 $3
}

get_source() {
	echo $4 $5 $6
}

# shuffle_t_source cfg [t_size t_source]
shuffle_t_source() {
	local cfg t_size t_source t_shift
	cfg="$1"
	t_size="${2:-0}"
	t_source="${3:-0}"
	t_shift="$( perl -e " 
  srand($cfg);

  # Call a few to clear out junk                                                                                                          
  foreach \$i (1 .. 20)
  {
    rand(1.0);
  }
  \$t_shift = int(rand($t_size));
  print \"\$t_shift\\n\"
")"
	if [ $t_size == 0 ]; then
		echo $t_shift
	else
		echo "$(( (t_source + t_shift) % t_size ))"
	fi
}

# k_split n args...
# Return args... broken in different lines with up to <n> elements in each line
k_split() {
	local n i f
	n="$1"
	shift
	i="0"
	for f in "$@" "__last_file__"; do
		if [ $f != "__last_file__" ]; then
			echo -n "$f "
			i="$(( i+1 ))"
			if [ $i == $n ]; then
				i="0"
				echo
			fi
		else
			[ $i != 0 ] && echo
		fi
	done
}

# k_split n args...
# Return args... broken in different up to <n> lines
k_split_lines() {
	local n i f num_args line
	n="$1"
	shift
	num_args="$#"
	i=0
	line=0
	for f in "$@" "__last_file__"; do
		if [ $f != "__last_file__" ]; then
			echo -n "$f "
			i="$(( i+1 ))"
			if [ $i == $(( num_args/n + (line<num_args%n ? 1 : 0) )) ]; then
				i="0"
				line="$(( line+1 ))"
				echo
			fi
		else
			[ $i != 0 ] && echo
		fi
	done
}
