import os
import toml
from pprint import pprint

class PackageManager:
    def __init__(self, packageManager) -> None:
        self.mgr = packageManager

    def install(self, packageName: str)->None:
        pass
        # os.system("sudo {} {}".format(manager, packageName))

    def install_list(self, packageList: list[str])->None:
        pass

    @staticmethod
    def cmd_install(cmdList: list[str])->None:
        for cmd in cmdList:
            os.system(cmd)

class AptManager(PackageManager):
    def install(self, packageName):
        os.system("sudo apt install {} -y".format(packageName))

    def install_list(self, packageList: list[str]) -> None:
        s = " ".join(packageList)
        os.system("sudo apt install {} -y".format(s))

def dispatch():
    
    pass



config = toml.load("./depencies.toml")
pprint(config)

