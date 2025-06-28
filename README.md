# Statgl-shortcodes Extension For Quarto

A Quarto extension that provides custom shortcodes for displaying
structured statistics from Statistics Greenland. The shortcodes make it
easier to render KPI cards, highlight boxes, and other elements commonly
used for public-facing statistical content.

## Installing

``` bash
quarto add StatisticsGreenland/statgl-shortcodes
```

This will install the extension under the `_extensions` subdirectory. If
you're using version control, you will want to check in this directory.

## Using

To use the extension, include it in your Quarto project’s _quarto.yml:

``` bash
project:
  type: website

contributes:
  shortcodes:
    - statgl-shortcodes
```

You can then use the provided shortcodes in your .qmd files.

## Examples

✅ **KPI card**
``` markdown
{{< kpicard 
  title = "Population" 
  subtitle = "As of January 2025" 
  value = "56,542" 
>}}
```

📈 **Plotbox**
``` markdown
{{< plotbox
  title = "Population over time"
  description = "From 1979 onwards"
  plot = '`r statgl::statgl_plot(statgl::statgl_fetch("BEXSTA"), time)`'
  link = "[See all poplation stats](https://example.com/population)"
  accordion = "Details and Method"
  more = "Here is a place to learn more about the graph"
>}}
```

📦 **Feature**
``` markdown
{{< feature
  eyebrow = "New Release"
  title = "2024 Population Forecast"
  subtitle = "Projections to 2050"
  icon = "bi-calendar3"
  body = "The forecast is based on birth rates, mortality, and net migration. §§§
          Projections are updated annually."
  link = "/forecast/population"
>}}
```

📇 **Contact**
```markdown
{{< contact
  title = "Contact the Author"
  phone = "+299 123456"
  mail = "enma@example.gl"
  icon = "bi-person-square"
>}}
```