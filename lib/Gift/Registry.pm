package Gift::Registry;
use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.2';

get '/example' => sub {
    template 'index';
};

get '/' => sub {
  
	my $sth = database->prepare(
		'select id, title, text from entries order by id desc',
    	);
    	$sth->execute or die $sth->errstr ;

	my $users_sth = database->prepare(
		'select id, username, realname, password from users order by id desc',
    	);
    	$users_sth->execute or die $users_sth->errstr ;

  template 'show_entries.tt', {
     'msg' => get_flash(),
     'add_entry_url' => uri_for('/add'),
     'add_users_url' => uri_for('/add_users'),     
     'entries' => $sth->fetchall_hashref('id'),
     'users' => $users_sth->fetchall_hashref('id'),
     
  };
}; #end of '/' sub


post '/add' => sub {
   if ( not session('logged_in') ) {
      send_error("Not logged in", 401);
   }
 
	my $sth = database->prepare(
   		'insert into entries (title, text) values (?, ?)',
	);
	$sth->execute(params->{'title'}, params->{'text'}) or die $sth->errstr;

   set_flash('New entry posted!');
   redirect '/';
}; #end of '/add' sub


post '/add_users' => sub {
   if ( not session('logged_in') ) {
      send_error("Not logged in", 401);
   }
 
	my $sth = database->prepare(
   		'insert into users (username, realname, password) values (?, ?, ?)',
	);
	$sth->execute(params->{'username'}, params->{'realname'}, 
		params->{'password'}) or die $sth->errstr;

   set_flash('user added!');
   
   redirect '/show_users';
}; #end of '/add_users' sub

any '/show_users' => sub {
   if ( not session('logged_in') ) {
      send_error("Not logged in", 401);
   }
   
	my $users_sth = database->prepare(
		'select id, username, realname, password from users order by id desc',
    	);
    	$users_sth->execute or die $users_sth->errstr ;
   
     template 'show_users.tt', {
     'msg' => get_flash(),
     'users' => $users_sth->fetchall_hashref('id'),
    'add_users_url' => uri_for('/add_users'), 
  };
   
}; #end of '/show_users' sub


any ['get', 'post'] => '/login' => sub {
   my $err;
 
   if ( request->method() eq "POST" ) {
     # process form input
     if ( params->{'username'} ne setting('username') ) {
       $err = "Invalid username";
     }
     elsif ( params->{'password'} ne setting('password') ) {
       $err = "Invalid password";
     }
     else {
       session 'logged_in' => true;
       set_flash('You are logged in.');
       return redirect '/';
     }
  }
 
  # display login form
  template 'login.tt', {
    'err' => $err,
  };
}; #end of '/login' sub

get '/logout' => sub {
   session->destroy;
   set_flash('You are logged out.');
   redirect '/';
}; #end of '/logout' sub

before_template sub {
   my $tokens = shift;
       
   $tokens->{'css_url'} = request->base . 'css/style.css';
   $tokens->{'login_url'} = uri_for('/login');
   $tokens->{'logout_url'} = uri_for('/logout');
}; #end of before_template sub

my $flash;
 
sub set_flash {
       my $message = shift;
 
       $flash = $message;
} #end of set_flash sub

sub get_flash {
 
       my $msg = $flash;
       $flash = "";
 
       return $msg;
}; #end of get_flash sub


true;
