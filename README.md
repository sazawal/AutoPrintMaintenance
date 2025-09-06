# AutoPrintMaintenance

Schedules a regular auto print job to print a test page with all the
different colors to prevent the printer ink from drying out
.
## Highlights

- Works on HP printers only, as of now
- Weekly, Bi-weekly or Monthly schedulers can be created
- A test page is generated with all the different colors
- CLI with commands to create, view, delete and disable the scheduler

## Environments and dependencies

- Works only on linux with installed python
- Requires https://pypi.org/project/reportlab/ reportlab dependency in python

## Workflow concept

1. The install script prompts the user to provide printer name.
2. The printer name is saved in the config file.
3. The source files are copied to the system folder. A launcher script is also created.
4. User creates a print scheduler via CLI by providing print frequency and print time.
5. Based on the user input the CLI creates a systemd service and timer.
6. After creating the systemd service and timer, the user can view the scheduler and test it on a connected printer.
7. The user can also enable, disable or delete the created scheduler.
8. At the scheduled time, systemd triggers the print script.
9. The print script generates a pdf file with all the different colors needed for maintenance, along with the current timestamp.
10. The pdf is printed on the current printer and the systemd service goes idle until the next trigger.

## Installation

1. Git clone the repository
2. Go to the created directory
```
$ cd AutoPrintMaintenance
```
3. Run the install script
```
$ ./install.sh
```
The install script sets the printer name, copies the source files and creates a launcher

## Usage

Usage: primauto [command]

Commands:
  enable     Enable an existing systemd primauto print job
  disable    Disable an existing systemd primauto print job (without deleting it)
  view       View job info, status, schedule, printer name, and open sample PDF
  configure  Create or overwrite the systemd primauto print job
  clear      Disable and delete the systemd primauto print job (service and timer files)
  test       Verify the systemd print job, and print the test page.
  help       Show this help message

## Uninstall

1. Go to the cloned directory (or git clone if not found)
```
$ cd AutoPrintMaintenance
```
2. Run the uninstall script
```
$ ./uninstall.sh
```
The uninstall script disables and removes any systemd scheduled print jobs, removes the launcher and removes the source files from the installation directory. No trace of the software remains in the system once uninstalled.
