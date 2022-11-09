package App::PerlDiver;

use 5.34.0;

use Moose;
use Moose::Util::TypeConstraints;

use Module::Pluggable;
use Path::Tiny;

use App::PerlDiver::Repo;
use PerlDiver::Schema;

coerce 'App::PerlDiver::Repo' =>
  from 'Str' =>
  via { App::PerlDiver::Repo->new(uri => $_) };

has repo => (
  is => 'ro',
  isa => 'App::PerlDiver::Repo',
  required => 1,
  coerce => 1,
);

has schema => (
  is => 'ro',
  isa => 'PerlDiver::Schema',
  lazy_build => 1,
);

sub _build_schema {
  return PerlDiver::Schema->get_schema;
}

sub run {
  my $self = shift;

  my ($db_repo) = $self->schema->resultset('Repo')->search({
    name => $self->repo->name,
    owner => $self->repo->owner,
  });

  my $run = $db_repo->add_to_runs({});

  $self->repo->clone;

  $self->gather($run);
  $self->render;

  $self->repo->unclone;
}

sub gather {
  my $self = shift;
  my ($run) = @_;

  for (@{$self->repo->files}) {
    say $_;
    my $file = path($_);
    my $path = $file->parent->stringify;
    my $name = $file->basename;

    my $db_file = $run->repo->files->find_or_create({
      path => $path,
      name => $name,
    });

    $run->add_to_run_files({
      file_id => $db_file->id,
    });
  }
}

sub render {
  my $self = shift;
}

1;
