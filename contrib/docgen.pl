#Documentation generator
#Daniel Lovasko 2012
#script takes one argument - source file name 
#generates documentation from commnets inside the source file

$filename = $ARGV[0];
$language = $ARGV[1];

# determine language "function" keyword
my %function_keyword_table = 
(
	"perl"   => "sub",
	"bash"   => "function",
	"python" => "def"
);

# get the function keyword in selected language
$function_keyword = $function_keyword_table{$language};
	
# try to open the source file 
open(my $source, "<", $filename)
	or die "No such file $filename\n";

# try to create the documentation file
open(my $documentation, ">", $filename . ".doc.html")
	or die "Unable to create file $filename.doc.html";

my $content_div = "";
my $detail_list = "";

# scan all lines of source
while(my $line = <$source>)
{	
	# if line starts with ##
	if($line =~ /^##/)
	{
		# main comment of the function
		my $comment = $line;

		my @globals = ();
		my @arguments = ();
		my @returns = ();

		# until we do not reach the actual function definition
		while(($line = <$source>) !~ /^$function_keyword/)
		{
			# delete the "# " at line start
			$line = substr($line, 2);
			
			# determine comment type
			if($line =~ /^global/)
			{
				# delete the "global " prefix
				$line = substr($line, 7);

				my %global = ();
				$global{'variable_name'} = substr($line, 0, index($line, " "));
				$global{'explanation'} = substr($line, index($line, " "));
				
				push(%global, @globals);
			}
			else if($line =~ /^arg/)
			{
				# delete the "arg " prefix
				$line = substr($line, 4);

				my %argument = ();
				$argument{'variable_type'} = substr($line, 0, index($line, " "));
				$argument{'explanation'} = substr($line, index($line, " "));
				
				push(%argument, @arguments);
			}
			else if($line =~ /^return/)
			{
				# delete the "return " prefix
				$line = substr($line, 7);

				my %return = ();
				$return{'variable_type'} = substr($line, 0, index($line, " "));
				$return{'explanation'} = substr($line, index($line, " "));

				push(%return, @returns);
			}
		}

		# get the function name from the line
		if(line =~ /$function_keyword ([a-zA-Z0-9_]*)[\(\s\n]/)
		{
			my $function_name = $1;
		}
		else
		{
			print "ERROR: Unable to determine the function name.\n";
			next;
		}
		
		# generate item in the "list of functions" section
		$content_div .= "<a href=\"$filename.doc.html#$function_name\">$line</a><br/>";
		
		# generate detail view of the function
		$detail_list .= "<div>";
		$detail_list .= "<h3>$function_name</h3>";
		$detail_list .= "<i>$comment</i><br/>";

		if(@arguments)
		{
			$detail_list .= "<b>Arguments</b>";

			$detail_list .= "<ul>"
			foreach $argument (@arguments)
			{
				my $type = $argument{'variable_type'};
				my $expl = $argument{'explanation'};

				$detail_list .= "<li>$expl : $type</li>\n";
			}
			$detail_list .= "</ul>";
		}

		if(@returns)
		{
			if(scalar(@returns) == 1)
			{
				
			}
			else
			{
				
			}
		}

		if(@globals)
		{
			$detail_list .= "<b>Global variables </b>";
			foreach $global (@globals) 
			{
				my $name = $global{'variable_name'};
				$detail_list .= " $name ";
			}
			$detail_list .= "<br/>";
		}
		
		$detail_list .= "</div>";
	}
}

# put parts together
print $documentation "<h2>" . $filename . "</h2>\n";
print $documentation $content_div;
print $documentation $detail_list;


# close file handles
close $source;
close $documentation;



