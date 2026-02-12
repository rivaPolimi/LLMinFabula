from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("game", "0002_auto_20260206_1054"),
    ]

    operations = [
        migrations.DeleteModel(
            name="RedisEventLog",
        ),
    ]
