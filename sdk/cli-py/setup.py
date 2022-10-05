#!/usr/bin/env python3
import setuptools

with open("README.MD", "r") as fh:
    long_description = fh.read()

with open("requirements.txt", "r") as fg:
    deps = fg.read().splitlines()


setuptools.setup(
    name="proca",
    version="0.3.3",
    author="Marcin Koziej",
    author_email="marcin@fixthestatusquo.org",
    description="Proca CLI to use with Proca service",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://proca.app",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU Affero General Public License v3",
        "Operating System :: OS Independent",
    ],
    entry_points={"console_scripts": ["proca = proca.main:cli"]},
    install_requires=deps,
    # package_data={"keanu": ["helpers/*.sql"]},
    # include_package_data=True,
)
