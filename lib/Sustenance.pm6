use v6;
use Sustenance::Parser::ParseTree;
use Sustenance::Parser;
use Sustenance::Types;
unit class Sustenance;

has Pantry:D $.pantry is required;
has Meal:D @.meal is required;

# submethod BUILD {{{

submethod BUILD(
    Pantry:D :$!pantry!,
    Meal:D :@!meal!
    --> Nil
)
{*}

# end submethod BUILD }}}
# method new {{{

multi method new(
    Str:D :$file! where .so
    --> Sustenance:D
)
{
    my %sustenance = from-sustenance(:$file);
    self.bless(|%sustenance);
}

multi method new(
    Str:D $content where .so
    --> Sustenance:D
)
{
    my %sustenance = from-sustenance($content);
    self.bless(|%sustenance);
}

# end method new }}}

# method gen-macros {{{

multi method gen-macros(::?CLASS:D: Date:D $d1, Date:D $d2 --> Hash:D)
{
    my Range:D $date-range = $d1 .. $d2;
    my Hash:D @meal =
        gen-macros($.pantry, @.meal).grep({ $date-range.in-range(.<date>) });
    my %macros = gen-macros(:@meal);
}

multi method gen-macros(::?CLASS:D: Date:D $date --> Hash:D)
{
    my Hash:D @meal =
        gen-macros($.pantry, @.meal).grep({ .<date> eqv $date });
    my %macros = gen-macros(:@meal);
}

multi method gen-macros(::?CLASS:D: --> Hash:D)
{
    my Hash:D @meal = gen-macros($.pantry, @.meal);
    my %macros = gen-macros(:@meal);
}

multi sub gen-macros(Pantry:D $pantry, Meal:D @m --> Array[Hash:D])
{
    my Hash:D @meal =
        @m.map(-> Meal:D $meal {
            my Date:D $date = $meal.date;
            my Time:D $time = $meal.time;
            my Portion:D @p = $meal.portion;
            my Hash:D @portion = gen-macros(@p, $pantry);
            my %meal = :$date, :$time, :@portion;
        });
}

multi sub gen-macros(Portion:D @p, Pantry:D $pantry --> Array[Hash:D])
{
    my Hash:D @portion =
        @p.map(-> Portion:D $portion {
            my FoodName:D $name = $portion.food;
            my Servings:D $servings = $portion.servings;
            my Food:D $food = $pantry.food.first({ .name eq $name });
            my Calories:D $calories = $food.calories * $servings;
            my Protein:D $protein = $food.protein * $servings;
            my Carbohydrates:D $carbohydrates = $food.carbohydrates * $servings;
            my Fat:D $fat = $food.fat * $servings;
            my %macros = :$calories, :$protein, :$carbohydrates, :$fat;
            my %portion = :food($name), :$servings, :%macros;
        });
}

multi sub gen-macros(Hash:D :@meal! --> Hash:D)
{
    my Hash:D @macros =
        @meal.map(-> %meal {
            my Hash:D @portion = %meal<portion>.Array;
            my %totals = gen-macros(:@portion);
            my %macros = :%meal, :%totals;
        });
    my %totals = gen-macros(:@macros);
    my %macros = :@macros, :%totals;
}

multi sub gen-macros(Hash:D :@portion! --> Hash:D)
{
    my (Calories:D $calories,
        Protein:D $protein,
        Carbohydrates:D $carbohydrates,
        Fat:D $fat) = 0.0;
    @portion.map(-> %portion {
        $calories += %portion<macros><calories>;
        $protein += %portion<macros><protein>;
        $carbohydrates += %portion<macros><carbohydrates>;
        $fat += %portion<macros><fat>;
    });
    my %macros = :$calories, :$protein, :$carbohydrates, :$fat;
}

multi sub gen-macros(Hash:D :@macros! --> Hash:D)
{
    my (Calories:D $calories,
        Protein:D $protein,
        Carbohydrates:D $carbohydrates,
        Fat:D $fat) = 0.0;
    @macros.map(-> %macros {
        $calories += %macros<totals><calories>;
        $protein += %macros<totals><protein>;
        $carbohydrates += %macros<totals><carbohydrates>;
        $fat += %macros<totals><fat>;
    });
    my %macros = :$calories, :$protein, :$carbohydrates, :$fat;
}

# end method gen-macros }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
