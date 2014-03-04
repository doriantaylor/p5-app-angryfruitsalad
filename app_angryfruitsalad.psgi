use strict;
use warnings;

use App::AngryFruitSalad;

my $app = App::AngryFruitSalad->apply_default_middlewares(App::AngryFruitSalad->psgi_app);
$app;

