## NcatPortable
Statically compiled, compressed, and self-signed Win32 `ncat.exe` for maximum portability.

**Latest release information below:**
| Resource | Version |
| --- | --- |
| Visual Studio | `Visual Studio 2026 Community Edition (February 2026 Update)` |
| Nmap | `v7.98` |
| OpenSSL | `v.3.6.1` |


## Compilation Instructions

Below you will find my approach and streamlined information, but if you want a more verbose wiki you can find the official instructions here: https://secwiki.org/w/Nmap/Ncat_Portable.

📁**Directory Structure:**
```
NcatPortable
|
|__ nmap
|   |__ <extracted_source_code>
|
|__ nmap-mswin32-aux
|   |__ OpenSSL
|       |__ <compilation_location>
|
|__ openssl
|   |__ <extracted_source_code>
|
|__ nmap-x.xx.tar.bz2     # Latest Release
|__ openssl-x.x.x.tar.gz  # Latest Release
|__ self-signer.sh        # Custom Self-Signing Script
```

_(Note: I use both Visual Studio and WSL for this process)_

---

#### **1. Download Latest Source Code Archives of OpenSSL and Nmap (or use the ones in this repository)**
- Nmap: https://nmap.org/download.html#source
- OpenSSL: https://github.com/openssl/openssl/releases/latest


#### **2. Download Windows Dependencies (PowerShell)**
```powershell
### Terminal 1 ###

# Install Perl & NASM to compile OpenSSL
winget install Strawberry.Perl.StrawberryPerl
winget install NASM.NASM

### Terminal 2 (after above install) ###

# Install required Perl module(s)
cpan -i Text::Template
cpan -i Text::More
```


#### **3. Expand Source Code Archives & Build Directory Structure (WSL)**
```shell
# Install WSL dependencies
sudo apt install bzip2 upx osslsigncode -y

# Expand source code archives
bzip2 -cd nmap-7.98.tar.bz2 | tar xvf -
tar -zxvf openssl-3.6.1.tar.gz

# Organize directories
mkdir nmap-mswin32-aux/OpenSSL -p
mv nmap-7.98 nmap
mv openssl-3.6.1 openssl
```


#### **4. Compile OpenSSL (x86 Native Tools Command Prompt for VS)**
```cmd
:: Validate NASM and Perl are in path 
perl --version
nasm --version

:: Change to OpenSSL source code & set output variable
cd /d <path_to_openssl_source_code>
set OUTDIR=<absolute_path_to_nmap-mswin32-aux/OpenSSL>

:: Configure OpenSSL makefile and compile
perl Configure --prefix=%OUTDIR% enable-weak-ssl-ciphers enable-ssl3 enable-ssl3-method VC-WIN32 no-shared
perl -pi -e "s|/debug|/NXCOMPAT /DYNAMICBASE /SAFESEH| if /^LDFLAGS/" makefile
nmake -f makefile install_dev

:: After successful compilation
copy ms\applink.c %OUTDIR%\include\openssl\applink.c
```
<img width="1316" height="1090" alt="image" src="https://github.com/user-attachments/assets/b05b2a1d-11aa-4dec-b67e-d0388646f91f" />


#### **5. Configure & Statically Compile 'ncat.exe' (Visual Studio)**
```
> Open Nmap solution file (location: "nmap/mswin32/nmap.sln")
> Retarget each Project to latest Platform Toolset 


> Right click on "nmap" solution --> "Properties" --> "Configuration Manager"
--> Change "Active Solution Configuration" to "Ncat Static"
--> Validate that "nbase", "ncat", and "nsock" projects all show "Static" as the select configuration.
--> Select "liblua" project to build.
--> Close "Configuration Manager"


> Right click on "liblua" solution --> "Properties"
--> Navigate to "Configuration Properties" --> "C/C++" --> "Code Generation"
--> Change "Runtime Library" to "Multi-threaded (/MT)"
--> Click "Apply".
--> Close"Properties".


> Right click on "ncat" solution --> "Properties"
--> Navigate to "Configuration Properties" --> "C/C++" --> "General"
--> Change "Additional Include Directories" to "<Edit...>"
--> Click "New Line" and add the path "..\liblua"
--> Click "OK".
--> Navigate to "Configuration Properties" --> "Linker" --> "Input"
--> Change "Additional Dependencies" to "<Edit...>"
--> Hit enter key for a new line and add "CRYPT32.LIB" to it.
--> Click "OK" to exit dependency editor.
--> Click "Apply" and "OK" to exit "Properties"


> Right click on "ncat" solution --> "Set as Startup Project"
> Right click on "nbase" solution --> "Build"
> Right click on "nsock" solution --> "Build"
> Right click on "ncat" solution --> "Build"


> Output: "nmap/ncat/Release/ncat.exe"
```


#### **6. Compress & Self-Sign 'ncat.exe' Binary (WSL)**
```shell
# Compress the compiled binary
cp nmap/ncat/Release/ncat.exe .
upx --best --brute ncat.exe

# Digitall sign the compiled binary
./self-signer.sh ncat.exe
```
<img width="1027" height="584" alt="image" src="https://github.com/user-attachments/assets/09e83602-ea96-4fce-8295-24e30ae22672" />
<img width="859" height="592" alt="image" src="https://github.com/user-attachments/assets/125d4fac-ef53-461e-a048-579970362dcd" />


