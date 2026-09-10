from dataclasses import dataclass, field
from typing import List, Dict, Optional
import logging
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

logger = logging.getLogger(__name__)

@dataclass
class TableResult:
    name: str
    layer: str
    status: str = "SUCCESS"
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    info: List[str] = field(default_factory=list)

@dataclass
class ProcessingReport:
    filename: str
    tables: List[TableResult] = field(default_factory=list)
    global_errors: List[str] = field(default_factory=list)
    global_warnings: List[str] = field(default_factory=list)
    global_info: List[str] = field(default_factory=list)
    
    def add_table(self, name: str, layer: str) -> TableResult:
        """Add a new table to track"""
        table = TableResult(name=name, layer=layer)
        self.tables.append(table)
        return table
    
    def add_error(self, message: str, table_name: str = None):
        """Add an error message, either global or table-specific"""
        if table_name:
            for table in self.tables:
                if table.name == table_name:
                    table.errors.append(message)
                    table.status = "ERROR"
                    break
            else:
                self.global_errors.append(message)
        else:
            self.global_errors.append(message)
    
    def add_warning(self, message: str, table_name: str = None):
        """Add a warning message, either global or table-specific"""
        if table_name:
            for table in self.tables:
                if table.name == table_name:
                    table.warnings.append(message)
                    if table.status != "ERROR":
                        table.status = "WARNING"
                    break
            else:
                self.global_warnings.append(message)
        else:
            self.global_warnings.append(message)
            
    def add_info(self, message: str, table_name: str = None):
        """Add an info message, either global or table-specific"""
        if table_name:
            for table in self.tables:
                if table.name == table_name:
                    table.info.append(message)
                    break
            else:
                self.global_info.append(message)
        else:
            self.global_info.append(message)

    @property
    def error_count(self) -> int:
        """Total error count across global errors and all table errors."""
        return len(self.global_errors) + sum(len(t.errors) for t in self.tables)

    def display(self):
        """Display the processing report using Rich"""
        console = Console()
        
        # Create the main header
        console.print(f"\n[bold blue]Processing Report for {self.filename}[/bold blue]")
        console.print("=" * 80)

        # Display global info if any
        if self.global_info:
            console.print("\n[bold]General Information[/bold]")
            for info in self.global_info:
                console.print(f"  • {info}")
        
        # Create tables summary
        if self.tables:
            summary_table = Table(show_header=True, header_style="bold")
            summary_table.add_column("Layer")
            summary_table.add_column("Table Name")
            summary_table.add_column("Status")
            summary_table.add_column("Messages")
            
            for result in sorted(self.tables, key=lambda x: (x.layer, x.name)):
                status_style = {
                    "SUCCESS": "green",
                    "WARNING": "yellow",
                    "ERROR": "red",
                    "SKIPPED": "blue"
                }.get(result.status, "white")
                
                # Count messages
                message_counts = []
                if result.errors:
                    message_counts.append(f"[red]{len(result.errors)} errors[/red]")
                if result.warnings:
                    message_counts.append(f"[yellow]{len(result.warnings)} warnings[/yellow]")
                if result.info:
                    message_counts.append(f"{len(result.info)} info")
                
                messages = ", ".join(message_counts) if message_counts else "-"
                
                summary_table.add_row(
                    result.layer,
                    result.name,
                    f"[{status_style}]{result.status}[/{status_style}]",
                    messages
                )
            
            console.print("\n[bold]Tables Processed[/bold]")
            console.print(summary_table)
        
        # Display errors and warnings
        if self.global_errors:
            console.print("\n[bold red]Global Errors[/bold red]")
            for error in self.global_errors:
                console.print(f"  • [red]{error}[/red]")
        
        if self.global_warnings:
            console.print("\n[bold yellow]Global Warnings[/bold yellow]")
            for warning in self.global_warnings:
                console.print(f"  • [yellow]{warning}[/yellow]")
        
        # Display detailed table issues
        for table in self.tables:
            has_messages = table.errors or table.warnings or table.info
            if has_messages:
                console.print(f"\n[bold]{table.layer} {table.name}[/bold]")
                
                if table.errors:
                    console.print("  [red]Errors:[/red]")
                    for error in table.errors:
                        console.print(f"    • [red]{error}[/red]")
                
                if table.warnings:
                    console.print("  [yellow]Warnings:[/yellow]")
                    for warning in table.warnings:
                        console.print(f"    • [yellow]{warning}[/yellow]")
                        
                if table.info:
                    console.print("  Info:")
                    for info in table.info:
                        console.print(f"    • {info}")
        
        console.print("\n" + "=" * 80 + "\n")

class ProcessReporter:
    def __init__(self):
        self.reports: Dict[str, ProcessingReport] = {}
    
    def start_file(self, filename: str) -> ProcessingReport:
        """Start tracking a new XLS file"""
        report = ProcessingReport(filename)
        self.reports[filename] = report
        return report
    
    def get_report(self, filename: str) -> Optional[ProcessingReport]:
        """Get the report for a specific file"""
        return self.reports.get(filename)
    
    def display_all(self):
        """Display all reports"""
        for report in self.reports.values():
            report.display()