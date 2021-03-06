package PACTray;

###############################################################################
# This file is part of Ásbrú Connection Manager
#
# Copyright (C) 2017 Ásbrú Connection Manager team (https://asbru-cm.net)
# Copyright (C) 2010-2016 David Torrejon Vaquerizas
# 
# Ásbrú Connection Manager is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Ásbrú Connection Manager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License version 3
# along with Ásbrú Connection Manager.
# If not, see <http://www.gnu.org/licenses/gpl-3.0.html>.
###############################################################################

$|++;

###################################################################
# Import Modules

# Standard
use strict;
use warnings;
use FindBin qw ( $RealBin $Bin $Script );

# GTK2
use Gtk2 '-init';

# PAC modules
use PACUtils;

# END: Import Modules
###################################################################

###################################################################
# Define GLOBAL CLASS variables

my $APPNAME			= $PACUtils::APPNAME;
my $APPVERSION		= $PACUtils::APPVERSION;
my $APPICON			= $RealBin . '/res/pac64x64.png';
my $TRAYICON		= $RealBin . '/res/pac_tray.png';
my $GROUPICON_ROOT	= _pixBufFromFile( $RealBin . '/res/pac_group.png' );
# END: Define GLOBAL CLASS variables
###################################################################

###################################################################
# START: Define PUBLIC CLASS methods

sub new {
	my $class	= shift;
	
	my $self	= {};
	
	$self -> {_MAIN}	= shift;
	
	$self -> {_TRAY}	= undef;
	
	$TRAYICON = $RealBin . '/res/pac_tray' . ( $$self{_MAIN}{_CFG}{defaults}{'use bw icon'} ? '_bw.png' : '.png' );

	# Build the GUI
	_initGUI( $self ) or return 0;

	# Setup callbacks
	_setupCallbacks( $self );
	
	bless( $self, $class );
	return $self;
}

# DESTRUCTOR
sub DESTROY {
	my $self = shift;
	undef $self;
	return 1;
}

# END: Define PUBLIC CLASS methods
###################################################################

###################################################################
# START: Define PRIVATE CLASS functions

sub _initGUI {
	my $self = shift;
	
	$$self{_TRAY} = Gtk2::StatusIcon -> new_from_file( $TRAYICON ) or die "ERROR: Could not create tray icon: $!";
	# Tray available (not Gnome-shell)?
	$$self{_TRAY} -> set_property( 'tooltip-markup', "<b>$APPNAME</b> (v.$APPVERSION)" );
	$$self{_TRAY} -> set_visible( $$self{_MAIN}{_CFG}{defaults}{'show tray icon'} );
	$$self{_MAIN}{_CFG}{'tmp'}{'tray available'} = $$self{_TRAY} -> is_embedded ? 1 : 'warning';
	
	return 1;
}

sub _setupCallbacks {
	my $self = shift;
	
	$$self{_TRAY} -> signal_connect( 'button_press_event' => sub {
		my ( $widget, $event ) = @_;
		
		( $event -> button eq 3 && ! $$self{_MAIN}{_GUI}{lockPACBtn} -> get_active ) and $self -> _trayMenu( $widget, $event );
		
		# Left click: show/hide main window
		return 1 unless $event -> button eq 1;
		
		if ( $$self{_MAIN}{_GUI}{main} -> visible ) {
			# Trigger the "lock" procedure
			$$self{_MAIN}{_GUI}{lockPACBtn} -> set_active( 1 ) if ( $$self{_MAIN}{_CFG}{'defaults'}{'use gui password'} && $$self{_MAIN}{_CFG}{'defaults'}{'use gui password tray'} );
			$$self{_MAIN} -> _hideConnectionsList;
		} else {
			# Check if show password is required
			if ( $$self{_MAIN}{_CFG}{'defaults'}{'use gui password'} && $$self{_MAIN}{_CFG}{'defaults'}{'use gui password tray'} ) {
				# Trigger the "unlock" procedure
				$$self{_MAIN}{_GUI}{lockPACBtn} -> set_active( 0 );
				if ( ! $$self{_MAIN}{_GUI}{lockPACBtn} -> get_active ) {
					$$self{_TRAY} -> set_visible( $$self{_MAIN}{_CFG}{defaults}{'show tray icon'} );
					$$self{_MAIN} -> _showConnectionsList;
				}
			} else {
				$$self{_TRAY} -> set_visible( $$self{_MAIN}{_CFG}{defaults}{'show tray icon'} );
				$$self{_MAIN} -> _showConnectionsList;
			}
		}
		
		return 1;
	} );
	
	return 1;	
}

sub _trayMenu {
	my $self	= shift;
	my $widget	= shift;
	my $event	= shift;
	
	my @m;
	
	push( @m, { label => 'Local Shell',		stockicon => 'gtk-home',			code => sub { $PACMain::FUNCS{_MAIN}{_GUI}{shellBtn} -> clicked; } } );
	push( @m, { separator => 1 } );
	push( @m, { label => 'Clusters',		stockicon => 'pac-cluster-manager',	submenu => _menuClusterConnections } );
	push( @m, { label => 'Favourites',		stockicon => 'pac-favourite-on',	submenu => _menuFavouriteConnections } );
	push( @m, { label => 'Connect to',		stockicon => 'pac-group',			submenu => _menuAvailableConnections( $PACMain::FUNCS{_MAIN}{_GUI}{treeConnections}{data} ) } );
	push( @m, { separator => 1 } );
	push( @m, { label => 'Preferences...',	stockicon => 'gtk-preferences',		code => sub { $$self{_MAIN}{_CONFIG} -> show; } } );
	push( @m, { label => 'Clusters...',		stockicon => 'gtk-justify-fill',	code => sub { $$self{_MAIN}{_CLUSTER} -> show; }  } );
	push( @m, { label => 'Show Window',		stockicon => 'gtk-home',			code => sub { $$self{_MAIN} -> _showConnectionsList; } } );
	push( @m, { separator => 1 } );
	push( @m, { label => 'About',		stockicon => 'gtk-about',			code => sub { $$self{_MAIN} -> _showAboutWindow; } }  );
	push( @m, { label => 'Exit',			stockicon => 'gtk-quit',			code => sub { $$self{_MAIN} -> _quitProgram; } } );
	
	_wPopUpMenu( \@m, $event, 'below calling widget' );
	
	return 1;
}

# END: Define PRIVATE CLASS functions
###################################################################

1;
