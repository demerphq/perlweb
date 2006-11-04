package CPANRatings::Control;
use strict;
use base qw(Combust::Control Combust::Control::Bitcard);
use Apache::Cookie;
use LWP::Simple qw(get);
use Apache::Util qw();
use CPANRatings::Model::Reviews;
use CPANRatings::Model::User;
use Encode qw();
use Apache::Constants qw(OK);
use XML::RSS;

our $cookie_name = 'cpruid';

sub init {
  my $self = shift;

  $self->bc_check_login_parameters;

  return OK;
}

sub bc_user_class {
  'CPANRatings::Model::User';
}

# old code here
sub user_info { shift->user(@_) }

sub bc_info_required {
  'username'
}


sub as_rss {
  my ($self, $reviews, $mode, $id) = @_;

  my $rss = XML::RSS->new(version => '1.0');
  my $link = "http://" . $self->config->site->{cpanratings}->{servername};
  if ($mode and $id) {
      $link .= ($mode eq "author" ? "/a/" : "/d/") . $id;
  }
  else {
      $link .= '/';
  }

  $rss->channel(
                title        => "CPAN Ratings: " . $self->tpl_param('header'),
                link         => $link, 
                description  => "CPAN Ratings: " . $self->tpl_param('header'),
                dc => {
                       date       => '2000-08-23T07:00+00:00',
                       subject    => "Perl",
                       creator    => 'ask@perl.org',
                       publisher  => 'ask@perl.org',
                       rights     => 'Copyright 2004, The Perl Foundation',
                       language   => 'en-us',
                      },
                syn => {
                        updatePeriod     => "daily",
                        updateFrequency  => "1",
                        updateBase       => "1901-01-01T00:00+00:00",
                       },
               );

  my $i; 
  while (my $review = $reviews->next) {
    my $text = substr($review->review, 0, 150);
    $text .= " ..." if (length $text < length $review->review);
    $text = "Rating: ". $review->rating_overall . " stars\n" . $text
      if ($review->rating_overall);
    $rss->add_item(
		   title       => (!$mode || $mode eq "author" ? $review->distribution : $review->user_name),
                   link        => "$link#" . $review->id,
                   description => $text,
                   dc => {
                          creator  => $review->user_name,
                         },
                  );    
    last if ++$i == 10;
  }
  
  my $output = $rss->as_string;
  $output = Encode::encode('utf8', $output);
  $self->{_utf8} = 1;
  $output;
}

1;
