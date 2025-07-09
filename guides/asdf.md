# ✅ asdf installation Ubuntu guide for dummies

## 1. Download the Binary

Go to: [https://github.com/asdf-vm/asdf/releases](https://github.com/asdf-vm/asdf/releases)

Under **Assets**, right-click the `.tar.gz` file for your OS/architecture and copy the link.

## 2. Back in the terminal, download the file:

`curl -LO <COPIED_URL>`

**Example:**

```bash
curl -LO https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz
```

---

## 3. Extract it to a directory on your `$PATH`

`sudo tar -xvzf asdf-YOUR_VERSION.tar.gz -C /YOUR_PATH`

**Example:**

```bash
sudo tar -xvzf asdf-v0.18.0-linux-amd64.tar.gz -C /usr/local/bin
```

Check if the binary is available:

`type -a asdf` should result in `asdf is /YOUR_PATH`, in our example `asdf is /usr/local/bin/asdf`

---

## 4. Configure shell

Edit shell config (`.bashrc`) in your favorite editor:

**Example:**

```bash
nano ~/.bashrc
```

Add these lines:

```bash
export PATH="$HOME/.asdf/shims:$PATH"
```

Add tool-versions in your to define global versions.
**Example:**

- Open/create file:

```bash
sudo nano /usr/local/bin/.tool-versions
```

- Paste the line:

```bash
erlang 25.2.2
elixir 1.14.4
```

Then reload the terminal with

```bash
source ~/.bashrc
```

or close/open.

Check if it works with

```bash
asdf --version
```
