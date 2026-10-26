<#
.SYNOPSIS
    Remote Deployment Console (Domain & Workgroup Edition)
#>

# STA Relaunch Guard
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    if (-not [string]::IsNullOrWhiteSpace($PSCommandPath) -and (Test-Path $PSCommandPath)) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Security, System.DirectoryServices

# ==========================================
# 1. MAIN WINDOW XAML
# ==========================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Remote Deployment Console" Height="860" Width="1260"
        MinHeight="640" MinWidth="980"
        WindowStartupLocation="CenterScreen" Background="#161822" Foreground="#CDD6F4"
        FontFamily="Segoe UI Variable Text, Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#25283B"/>
            <Setter Property="Foreground" Value="#F5E0DC"/>
            <Setter Property="BorderBrush" Value="#3D415B"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CaretBrush" Value="#89B4FA"/>
            <Setter Property="Padding" Value="6,3,6,3"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5" SnapsToDevicePixels="True">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="False"
                                          HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="BorderBrush" Value="#585B70"/>
                            </Trigger>
                            <Trigger Property="IsKeyboardFocused" Value="True">
                                <Setter TargetName="bd" Property="BorderBrush" Value="#89B4FA"/>
                                <Setter TargetName="bd" Property="Background" Value="#1E2030"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="PasswordBox">
            <Setter Property="Background" Value="#25283B"/>
            <Setter Property="Foreground" Value="#F5E0DC"/>
            <Setter Property="BorderBrush" Value="#3D415B"/>
            <Setter Property="CaretBrush" Value="#89B4FA"/>
            <Setter Property="Padding" Value="6,3,6,3"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#89B4FA"/>
            <Setter Property="Foreground" Value="#11111B"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,0,0,0"/>
            <Setter Property="Padding" Value="9,2"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              TextBlock.Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.92"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#B4BEFE"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.76"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Background" Value="#2E2E40"/>
                                <Setter Property="Foreground" Value="#6E7191"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TreeView">
            <Setter Property="Background" Value="#141620"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#2F334A"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style TargetType="TreeViewItem">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Padding" Value="5,3"/>
        </Style>
        <!-- Windows 11 Fluent Separator Style -->
        <Style TargetType="{x:Type Separator}">
            <Setter Property="Height" Value="1"/>
            <Setter Property="Margin" Value="8,5"/>
            <Setter Property="Background" Value="#34384E"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Separator}">
                        <Border Height="1" Background="{TemplateBinding Background}" Margin="{TemplateBinding Margin}" SnapsToDevicePixels="True"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <!-- Windows 11 Fluent ContextMenu Style (Rounded Acrylic-Dark Flyout + Soft DropShadow + Zero White Gutter) -->
        <Style TargetType="{x:Type ContextMenu}">
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Setter Property="Grid.IsSharedSizeScope" Value="True"/>
            <Setter Property="HasDropShadow" Value="True"/>
            <Setter Property="Background" Value="#202230"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="BorderBrush" Value="#3B3F58"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ContextMenu}">
                        <Border x:Name="Win11MenuBorder"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}"
                                Margin="10"
                                SnapsToDevicePixels="True">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="18" ShadowDepth="4" Direction="270" Color="#000000" Opacity="0.60"/>
                            </Border.Effect>
                            <ScrollViewer CanContentScroll="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" MaxHeight="450">
                                <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Cycle"/>
                            </ScrollViewer>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <!-- Windows 11 Fluent MenuItem Style (Pill Hover, Rounded Checkmark Badge, Right Shortcut Hint, Submenu Flyout) -->
        <Style TargetType="{x:Type MenuItem}">
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="FontSize" Value="12.5"/>
            <Setter Property="FontFamily" Value="Segoe UI Variable Text, Segoe UI"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="Margin" Value="2,1"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type MenuItem}">
                        <Border x:Name="templateRoot"
                                Background="{TemplateBinding Background}"
                                BorderBrush="Transparent"
                                BorderThickness="1"
                                CornerRadius="5"
                                Margin="{TemplateBinding Margin}"
                                Padding="{TemplateBinding Padding}"
                                SnapsToDevicePixels="True">
                            <Grid VerticalAlignment="Center">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="26"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid Grid.Column="0" Width="22" Height="20" VerticalAlignment="Center" HorizontalAlignment="Left">
                                    <ContentPresenter x:Name="Icon" ContentSource="Icon" VerticalAlignment="Center" HorizontalAlignment="Center" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"/>
                                    <Border x:Name="GlyphPanel" Width="18" Height="18" CornerRadius="4" Background="#89B4FA" Visibility="Collapsed" VerticalAlignment="Center" HorizontalAlignment="Center">
                                        <TextBlock Text="✓" Foreground="#11111B" FontWeight="Bold" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-1,0,0"/>
                                    </Border>
                                </Grid>
                                <ContentPresenter Grid.Column="1" ContentSource="Header" RecognizesAccessKey="True" VerticalAlignment="Center" Margin="4,0,10,0" SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"/>
                                <TextBlock x:Name="InputGestureText" Grid.Column="2" Text="{TemplateBinding InputGestureText}" Foreground="#9399B2" FontSize="11" VerticalAlignment="Center" Margin="16,0,4,0"/>
                                <TextBlock x:Name="SubMenuArrow" Grid.Column="3" Text="›" Foreground="#9399B2" FontSize="15" FontWeight="SemiBold" VerticalAlignment="Center" Margin="4,-2,2,0" Visibility="Collapsed"/>
                                <Popup x:Name="PART_Popup" AllowsTransparency="True" Placement="Right" HorizontalOffset="-2" VerticalOffset="-4"
                                       IsOpen="{Binding IsSubmenuOpen, RelativeSource={RelativeSource TemplatedParent}}"
                                       PopupAnimation="Fade" Focusable="False">
                                    <Border Background="#202230" BorderBrush="#3B3F58" BorderThickness="1" CornerRadius="8" Padding="5" Margin="10" SnapsToDevicePixels="True">
                                        <Border.Effect>
                                            <DropShadowEffect BlurRadius="16" ShadowDepth="4" Direction="270" Color="#000000" Opacity="0.60"/>
                                        </Border.Effect>
                                        <ScrollViewer CanContentScroll="True" VerticalScrollBarVisibility="Auto" MaxHeight="380">
                                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Cycle"/>
                                        </ScrollViewer>
                                    </Border>
                                </Popup>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="Icon" Value="{x:Null}">
                                <Setter TargetName="Icon" Property="Visibility" Value="Collapsed"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="GlyphPanel" Property="Visibility" Value="Visible"/>
                                <Setter TargetName="Icon" Property="Visibility" Value="Collapsed"/>
                            </Trigger>
                            <Trigger Property="Role" Value="SubmenuHeader">
                                <Setter TargetName="SubMenuArrow" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="templateRoot" Property="Background" Value="#31354B"/>
                                <Setter TargetName="templateRoot" Property="BorderBrush" Value="#434868"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#7F849C"/>
                                <Setter TargetName="templateRoot" Property="Background" Value="Transparent"/>
                                <Setter TargetName="templateRoot" Property="BorderBrush" Value="Transparent"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#232638"/>
            <Setter Property="Foreground" Value="#89B4FA"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="7,5"/>
            <Setter Property="BorderBrush" Value="#343850"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="DataGridCell">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="6,4"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#363B59"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGridRow">
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#292D42"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#363B59"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <ControlTemplate x:Key="ComboBoxToggleButtonTemplate" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition />
                    <ColumnDefinition Width="24" />
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" Background="#25283B" BorderBrush="#3D415B" BorderThickness="1" CornerRadius="5" />
                <Path x:Name="Arrow" Grid.Column="1" Fill="#89B4FA" HorizontalAlignment="Center" VerticalAlignment="Center" Data="M 0 0 L 4 4 L 8 0 Z"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Border" Property="Background" Value="#2E324B" />
                    <Setter TargetName="Border" Property="BorderBrush" Value="#89B4FA" />
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>
        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Background" Value="#25283B"/>
            <Setter Property="BorderBrush" Value="#3D415B"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton" Template="{StaticResource ComboBoxToggleButtonTemplate}" Grid.Column="2" Focusable="false" IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press"/>
                            <ContentPresenter Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" Margin="8,3,24,3" VerticalAlignment="Center" HorizontalAlignment="Left" />
                            <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
                                <Grid Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}" Margin="8">
                                    <Border x:Name="DropDownBorder" Background="#202230" BorderThickness="1" BorderBrush="#3B3F58" CornerRadius="8" Padding="3">
                                        <Border.Effect>
                                            <DropShadowEffect BlurRadius="14" ShadowDepth="3" Direction="270" Color="#000000" Opacity="0.55"/>
                                        </Border.Effect>
                                    </Border>
                                    <ScrollViewer Margin="4" SnapsToDevicePixels="True">
                                        <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" />
                                    </ScrollViewer>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="Margin" Value="2,1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="5" Margin="{TemplateBinding Margin}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#31354B"/>
                                <Setter Property="Foreground" Value="#89B4FA"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#3D425E"/>
                                <Setter Property="Foreground" Value="#A6E3A1"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition x:Name="rowUpperWorkspace" Height="2.6*" MinHeight="260"/>
            <RowDefinition Height="8"/>
            <RowDefinition x:Name="rowStatusLog" Height="1*" MinHeight="115"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- ROW 0: TOP HEADER BAR -->
        <Border Grid.Row="0" Background="#1D1F2D" BorderBrush="#2F334A" BorderThickness="1" CornerRadius="8" Padding="14,9" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🚀 Remote Deployment Console" FontSize="18" FontWeight="Bold" Foreground="#89B4FA"/>
                    <TextBlock Text=" | Multi-step package deployment with live status" FontSize="12" Foreground="#A6ADC8" Margin="10,3,0,0"/>
                </StackPanel>
                <TextBlock x:Name="lblSettingsSummary" Grid.Column="1" Text="Auth: Loading... | Staging: C:\Temp\PSDeploy" 
                           Foreground="#A6ADC8" FontSize="11" VerticalAlignment="Center" Margin="15,0,15,0" TextTrimming="CharacterEllipsis"/>
                <Button x:Name="btnSettings" Grid.Column="2" Content="⚙️ Settings" Width="Auto" Height="30" Padding="12,2" 
                        Background="#CBA6F7" Foreground="#11111B" FontWeight="Bold" Cursor="Hand" Margin="0"
                        ToolTip="Configure Active Directory Admin Credentials, Local Config Directory, and Remote Staging Directory"/>
            </Grid>
        </Border>

        <!-- ROW 1: UPPER 2-COLUMN WORKSPACE (PACKAGE LIBRARY ON LEFT, TARGET COMPUTERS & PACKAGE STEPS ON RIGHT) -->
        <Grid Grid.Row="1" Margin="0,0,0,2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition x:Name="colPackageLibrary" Width="290" MinWidth="180"/>
                <ColumnDefinition Width="8"/>
                <ColumnDefinition x:Name="colRightStack" Width="*" MinWidth="420"/>
            </Grid.ColumnDefinitions>

            <!-- COL 0: PACKAGE LIBRARY (SPANS FULL LEFT SIDE) -->
            <Border Grid.Column="0" Background="#1D1F2D" BorderBrush="#2F334A" BorderThickness="1" CornerRadius="8" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="📚 PACKAGE LIBRARY" FontWeight="Bold" Foreground="#CBA6F7" Margin="0,0,0,6"/>
                    <WrapPanel Grid.Row="1" Margin="0,0,0,6">
                        <Button x:Name="btnNewPkg" Content="＋ New" Background="#89B4FA" Foreground="#11111B" Height="26" Width="Auto" Padding="8,2" FontSize="11" Margin="0,0,4,4" ToolTip="Create a new deployment package in the Package Steps Builder modal"/>
                        <Button x:Name="btnNewFolder" Content="📁 Folder" Background="#2B2E44" Foreground="#CBA6F7" BorderBrush="#3D415B" Height="26" Width="Auto" Padding="8,2" FontSize="11" Margin="0,0,4,4" ToolTip="Create a new folder in the Package Library"/>
                        <Button x:Name="btnDeletePkg" Content="🗑 Delete" Background="#2B2E44" Foreground="#F38BA8" BorderBrush="#3D415B" Height="26" Width="Auto" Padding="8,2" FontSize="11" Margin="0,0,0,4" ToolTip="Delete the selected package or folder from the Package Library"/>
                    </WrapPanel>
                    <TreeView x:Name="tvLibrary" Grid.Row="2" VerticalAlignment="Stretch" Background="#141620" Foreground="#CDD6F4" BorderBrush="#2F334A" BorderThickness="1" AllowDrop="True" ToolTip="Select a package to load it, double-click to edit its steps, or right-click for actions">
                        <TreeView.Resources>
                            <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#2563EB"/>
                            <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="#FFFFFF"/>
                            <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightBrushKey}" Color="#2563EB"/>
                            <SolidColorBrush x:Key="{x:Static SystemColors.InactiveSelectionHighlightTextBrushKey}" Color="#FFFFFF"/>
                            <Style TargetType="TreeViewItem">
                                <Setter Property="Foreground" Value="#CDD6F4"/>
                                <Setter Property="Background" Value="Transparent"/>
                                <Setter Property="Padding" Value="6,3"/>
                                <Setter Property="Margin" Value="0,1"/>
                                <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
                                <Style.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter Property="Background" Value="#2563EB"/>
                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                    </Trigger>
                                    <MultiTrigger>
                                        <MultiTrigger.Conditions>
                                            <Condition Property="IsSelected" Value="True"/>
                                            <Condition Property="IsSelectionActive" Value="False"/>
                                        </MultiTrigger.Conditions>
                                        <Setter Property="Background" Value="#2563EB"/>
                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                    </MultiTrigger>
                                </Style.Triggers>
                            </Style>
                        </TreeView.Resources>
                        <TreeView.ContextMenu>
                            <ContextMenu>
                                <MenuItem x:Name="menuLibEditSteps" Header="Edit Package Steps..." InputGestureText="Enter">
                                    <MenuItem.Icon><TextBlock Text="📦" Foreground="#89B4FA" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                                <MenuItem x:Name="menuLibNewFolder" Header="New Folder..." InputGestureText="Folder">
                                    <MenuItem.Icon><TextBlock Text="📁" Foreground="#CBA6F7" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                                <MenuItem x:Name="menuLibSaveHere" Header="Save Current Package Here" InputGestureText="Ctrl+S">
                                    <MenuItem.Icon><TextBlock Text="💾" Foreground="#A6E3A1" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                                <MenuItem x:Name="menuLibRename" Header="Rename Selected..." InputGestureText="F2">
                                    <MenuItem.Icon><TextBlock Text="&#x270F;" Foreground="#F9E2AF" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                                <Separator/>
                                <MenuItem x:Name="menuLibImport" Header="Import Package..." InputGestureText="JSON">
                                    <MenuItem.Icon><TextBlock Text="📥" Foreground="#A6E3A1" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                                <MenuItem x:Name="menuLibExport" Header="Export Package..." InputGestureText="JSON">
                                    <MenuItem.Icon><TextBlock Text="📤" Foreground="#89B4FA" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                                <Separator/>
                                <MenuItem x:Name="menuLibDelete" Header="Delete Selected" InputGestureText="Del" Foreground="#F38BA8">
                                    <MenuItem.Icon><TextBlock Text="🗑" Foreground="#F38BA8" FontSize="12" HorizontalAlignment="Center"/></MenuItem.Icon>
                                </MenuItem>
                            </ContextMenu>
                        </TreeView.ContextMenu>
                    </TreeView>
                </Grid>
            </Border>

            <!-- COL 1: VERTICAL SPLITTER -->
            <GridSplitter x:Name="splitLibraryRight" Grid.Column="1" Width="6" HorizontalAlignment="Center" VerticalAlignment="Stretch"
                          Background="#313244" ResizeDirection="Columns" ResizeBehavior="PreviousAndNext"
                          ShowsPreview="False" Cursor="SizeWE"
                          ToolTip="Drag left or right to resize Package Library and Target Computers"/>

            <!-- COL 2: RIGHT STACK (TARGET COMPUTERS + PACKAGE STEPS) -->
            <Grid Grid.Column="2">
                <Grid.RowDefinitions>
                    <RowDefinition x:Name="rowTargetComputers" Height="1*" MinHeight="110"/>
                    <RowDefinition Height="8"/>
                    <RowDefinition x:Name="rowPackageSteps" Height="1*" MinHeight="110"/>
                </Grid.RowDefinitions>

                <!-- RIGHT ROW 0: TARGET COMPUTERS DISCOVERY TABLE -->
                <Border Grid.Row="0" Background="#181825" CornerRadius="6" Padding="10">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <DockPanel Grid.Row="0" Margin="0,0,0,6">
                            <TextBlock Text="🎯 COMPUTER INVENTORY" FontWeight="Bold" Foreground="#A6E3A1" VerticalAlignment="Center"/>
                            <TextBlock x:Name="lblAdSyncStatusBadge" Text="" Foreground="#89DCEB" FontSize="11.5" Margin="12,0,0,0" VerticalAlignment="Center" DockPanel.Dock="Right" HorizontalAlignment="Right"/>
                        </DockPanel>
                        <Grid Grid.Row="1" Margin="0,0,0,6">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="180"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Computer:" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="0,0,6,0"/>
                            <TextBox x:Name="txtSingleComp" Grid.Column="1" Height="28" Margin="0,0,6,0"
                                     ToolTip="Enter hostname, FQDN (e.g. pc01.domain.local), IP address, or comma-separated list"/>
                            <Button x:Name="btnAddTargets" Grid.Column="2" Content="&#xFF0B; Add" Background="#89B4FA" Foreground="#11111B" Width="Auto" Padding="10,2" Height="28" Margin="0,0,6,0" ToolTip="Add entered computer(s) to Computer Inventory and probe live status"/>
                            <Button x:Name="btnBrowseAD" Grid.Column="3" Content="&#x1F504; Sync AD" Width="96" Height="28" Margin="0,0,6,0" Background="#89DCEB" Foreground="#11111B" FontWeight="Bold" ToolTip="Configure PDQ-style Active Directory Sync (select one or multiple OUs, set sync frequency, delete mode, and sync computers)"/>
                            <Button x:Name="btnRefreshTargets" Grid.Column="4" Content="&#x1F504; Probe" Background="#45475A" Foreground="#CDD6F4" Width="Auto" Padding="10,2" Height="28" Margin="0,0,6,0" ToolTip="Probe / refresh Online Status, IP Address, and Logon User for all inventory computers"/>
                            <Button x:Name="btnSelectAllTargets" Grid.Column="5" Content="&#x2611; All / None" Background="#45475A" Foreground="#CDD6F4" Width="Auto" Padding="10,2" Height="28" Margin="0,0,6,0" ToolTip="Toggle Deploy selection for all visible inventory computers"/>
                            <Button x:Name="btnRemoveTarget" Grid.Column="6" Content="&#x2715; Remove" Background="#45475A" Foreground="#CDD6F4" Width="Auto" Padding="10,2" Height="28" Margin="0,0,10,0" ToolTip="Remove selected row from Computer Inventory table"/>
                        </Grid>
                        <DataGrid x:Name="dgTargets" Grid.Row="2" AutoGenerateColumns="False" CanUserSortColumns="True" CanUserAddRows="False" CanUserDeleteRows="False" VerticalAlignment="Stretch"
                                  SelectionMode="Single" HeadersVisibility="Column" RowHeaderWidth="0"
                                  Background="#181825" Foreground="#CDD6F4" RowBackground="#1E1E2E" AlternatingRowBackground="#313244"
                                  GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#45475A" BorderThickness="0">
                            <DataGrid.Columns>
                                <DataGridTemplateColumn Width="86" CanUserSort="True" SortMemberPath="Selected">
                                    <DataGridTemplateColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="Deploy ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Deploy checked state"/>
                                                <Button x:Name="btnTargetHeaderMenu_Selected" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="3,0,0,0" ToolTip="Sort &amp; Filter options for Deploy column"/>
                                            </Grid>
                                            <ComboBox x:Name="cmbFilterTarget_Selected" Height="21" FontSize="10.5" Padding="2,0" ToolTip="Filter by Deploy checkbox state (All, Checked, Unchecked)">
                                                <ComboBoxItem Content="All" IsSelected="True"/>
                                                <ComboBoxItem Content="Checked"/>
                                                <ComboBoxItem Content="Unchecked"/>
                                            </ComboBox>
                                        </StackPanel>
                                    </DataGridTemplateColumn.Header>
                                    <DataGridTemplateColumn.CellTemplate>
                                        <DataTemplate>
                                            <CheckBox IsChecked="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"
                                                      HorizontalAlignment="Center" VerticalAlignment="Center"
                                                      Focusable="False" Cursor="Hand"/>
                                        </DataTemplate>
                                    </DataGridTemplateColumn.CellTemplate>
                                </DataGridTemplateColumn>
                                <DataGridTextColumn Binding="{Binding ComputerName}" Width="195" CanUserSort="True" SortMemberPath="ComputerName" IsReadOnly="True">
                                    <DataGridTextColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="Computer Name ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Computer Name"/>
                                                <Button x:Name="btnTargetHeaderMenu_ComputerName" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Computer Name"/>
                                            </Grid>
                                            <TextBox x:Name="txtFilterTarget_ComputerName" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Target Computers by Computer Name"/>
                                        </StackPanel>
                                    </DataGridTextColumn.Header>
                                </DataGridTextColumn>
                                <DataGridTextColumn Binding="{Binding OnlineStatus}" Width="125" CanUserSort="True" SortMemberPath="OnlineStatus" IsReadOnly="True">
                                    <DataGridTextColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="Online Status ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Online Status"/>
                                                <Button x:Name="btnTargetHeaderMenu_OnlineStatus" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Online Status"/>
                                            </Grid>
                                            <TextBox x:Name="txtFilterTarget_OnlineStatus" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter by Online Status (e.g. Online, Offline)"/>
                                        </StackPanel>
                                    </DataGridTextColumn.Header>
                                </DataGridTextColumn>
                                <DataGridTextColumn Binding="{Binding IPAddress}" Width="145" CanUserSort="True" SortMemberPath="IPAddress" IsReadOnly="True">
                                    <DataGridTextColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="IP Address ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by IP Address"/>
                                                <Button x:Name="btnTargetHeaderMenu_IPAddress" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for IP Address"/>
                                            </Grid>
                                            <TextBox x:Name="txtFilterTarget_IPAddress" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter by IP Address"/>
                                        </StackPanel>
                                    </DataGridTextColumn.Header>
                                </DataGridTextColumn>
                                <DataGridTextColumn Binding="{Binding LogonUser}" Width="165" CanUserSort="True" SortMemberPath="LogonUser" IsReadOnly="True">
                                    <DataGridTextColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="Current Logon User ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Current Logon User"/>
                                                <Button x:Name="btnTargetHeaderMenu_LogonUser" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Current Logon User"/>
                                            </Grid>
                                            <TextBox x:Name="txtFilterTarget_LogonUser" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter by Current Logon User"/>
                                        </StackPanel>
                                    </DataGridTextColumn.Header>
                                </DataGridTextColumn>
                                <DataGridTextColumn Binding="{Binding OUPath}" Width="*" MinWidth="220" CanUserSort="True" SortMemberPath="OUPath" IsReadOnly="True">
                                    <DataGridTextColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="AD OU Path ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Active Directory OU Path"/>
                                                <Button x:Name="btnTargetHeaderMenu_OUPath" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for AD OU Path"/>
                                            </Grid>
                                            <TextBox x:Name="txtFilterTarget_OUPath" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter by Active Directory OU Path"/>
                                        </StackPanel>
                                    </DataGridTextColumn.Header>
                                </DataGridTextColumn>
                                <DataGridTextColumn Binding="{Binding ADLastLogon}" Width="145" CanUserSort="True" SortMemberPath="ADLastLogon" IsReadOnly="True">
                                    <DataGridTextColumn.Header>
                                        <StackPanel Margin="0,1">
                                            <Grid Margin="0,0,0,3">
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Grid.Column="0" Text="AD Last Logon ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Active Directory Last Logon Timestamp"/>
                                                <Button x:Name="btnTargetHeaderMenu_ADLastLogon" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for AD Last Logon"/>
                                            </Grid>
                                            <TextBox x:Name="txtFilterTarget_ADLastLogon" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter by AD Last Logon Timestamp"/>
                                        </StackPanel>
                                    </DataGridTextColumn.Header>
                                </DataGridTextColumn>
                            </DataGrid.Columns>
                        </DataGrid>
                        <Border Grid.Row="3" Background="#11111B" CornerRadius="4" Padding="8,4" Margin="0,6,0,0" BorderBrush="#313244" BorderThickness="1">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="Checked / Imported: " Foreground="#A6ADC8" FontSize="11.5" FontWeight="SemiBold" VerticalAlignment="Center"/>
                                    <TextBlock x:Name="lblTargetCount" Text="0/0" Foreground="#A6E3A1" FontSize="12" FontWeight="Bold" VerticalAlignment="Center" ToolTip="Number of checked target computers out of total imported target computers"/>
                                    <TextBlock x:Name="lblTargetCountDetail" Text=" (0 checked of 0 imported)" Foreground="#A6ADC8" FontSize="11" VerticalAlignment="Center" Margin="6,0,0,0"/>
                                    <Border Width="1" Height="14" Background="#45475A" Margin="10,0"/>
                                    <TextBlock Text="🟢 Online: " Foreground="#A6E3A1" FontSize="11.5" FontWeight="SemiBold" VerticalAlignment="Center"/>
                                    <TextBlock x:Name="lblTargetOnlineCount" Text="0" Foreground="#A6E3A1" FontSize="12" FontWeight="Bold" VerticalAlignment="Center" ToolTip="Number of target computers in inventory currently Online"/>
                                    <TextBlock Text="   🔴 Offline: " Foreground="#F38BA8" FontSize="11.5" FontWeight="SemiBold" VerticalAlignment="Center"/>
                                    <TextBlock x:Name="lblTargetOfflineCount" Text="0" Foreground="#F38BA8" FontSize="12" FontWeight="Bold" VerticalAlignment="Center" ToolTip="Number of target computers in inventory currently Offline"/>
                                </StackPanel>
                                <Button x:Name="btnClearTargetFilters" Grid.Column="1" Content="🧹 Clear Filters" Height="22" Width="Auto" Padding="8,1" FontSize="10.5" Background="#313244" Foreground="#CDD6F4" ToolTip="Clear all column header filters and sorting in Target Computers"/>
                            </Grid>
                        </Border>
                    </Grid>
                </Border>

                <!-- RIGHT ROW 1: HORIZONTAL SPLITTER -->
                <GridSplitter x:Name="splitTargetsSteps" Grid.Row="1" Height="6" HorizontalAlignment="Stretch" VerticalAlignment="Center"
                              Background="#313244" ResizeDirection="Rows" ResizeBehavior="PreviousAndNext"
                              ShowsPreview="False" Cursor="SizeNS"
                              ToolTip="Drag up or down to resize Target Computers and Package Steps"/>

                <!-- RIGHT ROW 2: DEPLOYMENT PANEL (RUNNING DEPLOYMENTS & DEPLOYMENT HISTORY) -->
                <Border Grid.Row="2" Background="#181825" CornerRadius="6" Padding="10">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <!-- Deployment Header & Actions Bar -->
                        <Grid Grid.Row="0" Margin="0,0,0,6">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                <TextBlock Text="🚀 DEPLOYMENT" FontWeight="Bold" Foreground="#89B4FA" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                <Border Background="#11111B" BorderBrush="#313244" BorderThickness="1" CornerRadius="4" Padding="8,2">
                                    <TextBlock x:Name="lblDeployActivePkg" Text="Active Package: Custom Deployment Package (0 steps)" Foreground="#A6E3A1" FontSize="11.5" FontWeight="SemiBold"/>
                                </Border>
                            </StackPanel>
                            <Button x:Name="btnSelectAllDeployPkgs" Grid.Column="2" Content="🧹 Clear History" Height="27" Width="Auto" Padding="10,2" FontSize="11" Background="#45475A" Foreground="#CDD6F4" Margin="0,0,6,0" ToolTip="Clear completed deployment runs from Deployment History"/>
                            <Button x:Name="btnOpenStepsModal" Grid.Column="3" Content="📦 Edit Package Steps..." Visibility="Collapsed" Height="27" Width="Auto" Padding="12,2" FontSize="11.5" Background="#89B4FA" Foreground="#11111B" FontWeight="Bold" Margin="0,0,6,0"/>
                            <Button x:Name="btnDeployCheckedPkgs" Grid.Column="4" Content="🚀 Deploy Checked Packages" Visibility="Collapsed" Height="27" Width="Auto" Padding="12,2" FontSize="11.5" Background="#CBA6F7" Foreground="#11111B" FontWeight="Bold" Margin="0,0,6,0"/>
                            <Button x:Name="btnDeployActiveNow" Grid.Column="5" Content="🚀 Deploy Selected Package" Height="27" Width="Auto" Padding="12,2" FontSize="11.5" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" Margin="0" ToolTip="Deploy the currently selected package in the background to checked computers"/>
                        </Grid>

                        <!-- Full-Width Running Deployments & Deployment History Table -->
                        <Border Grid.Row="1" Background="#141620" BorderBrush="#2F334A" BorderThickness="1" CornerRadius="5" Padding="6">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <TextBlock Grid.Row="0" Text="Running Deployments &amp; Deployment History (select a deployment task below to view its target computer status in the Status Log):" Foreground="#A6ADC8" FontSize="11" Margin="2,0,0,4"/>
                                <DataGrid x:Name="dgDeployPackages" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" CanUserSortColumns="True" CanUserAddRows="False" CanUserDeleteRows="False"
                                          SelectionMode="Single" HeadersVisibility="Column" RowHeaderWidth="0"
                                          Background="#141620" Foreground="#CDD6F4" RowBackground="#1E1E2E" AlternatingRowBackground="#313244"
                                          GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#45475A" BorderThickness="0"
                                          ToolTip="Select a running or completed deployment task to view its computer status in the Status Log below">
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="Deployment Task / Package" Binding="{Binding PackageName}" Width="1.5*" IsReadOnly="True"/>
                                        <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="140" IsReadOnly="True">
                                            <DataGridTextColumn.ElementStyle>
                                                <Style TargetType="TextBlock">
                                                    <Setter Property="FontWeight" Value="Bold"/>
                                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                                    <Setter Property="Margin" Value="6,0"/>
                                                    <Style.Triggers>
                                                        <DataTrigger Binding="{Binding Status}" Value="Running">
                                                            <Setter Property="Foreground" Value="#F9E2AF"/>
                                                        </DataTrigger>
                                                        <DataTrigger Binding="{Binding Status}" Value="Success">
                                                            <Setter Property="Foreground" Value="#A6E3A1"/>
                                                        </DataTrigger>
                                                        <DataTrigger Binding="{Binding Status}" Value="Failed">
                                                            <Setter Property="Foreground" Value="#F38BA8"/>
                                                        </DataTrigger>
                                                        <DataTrigger Binding="{Binding Status}" Value="Completed (Partial)">
                                                            <Setter Property="Foreground" Value="#FAB387"/>
                                                        </DataTrigger>
                                                        <DataTrigger Binding="{Binding Status}" Value="Stopped">
                                                            <Setter Property="Foreground" Value="#F9E2AF"/>
                                                        </DataTrigger>
                                                    </Style.Triggers>
                                                </Style>
                                            </DataGridTextColumn.ElementStyle>
                                        </DataGridTextColumn>
                                        <DataGridTextColumn Header="Target Progress" Binding="{Binding TargetSummary}" Width="195" IsReadOnly="True"/>
                                        <DataGridTextColumn Header="Steps" Binding="{Binding StepsCount}" Width="60" IsReadOnly="True"/>
                                        <DataGridTextColumn Header="Start Time" Binding="{Binding StartTime}" Width="140" IsReadOnly="True"/>
                                        <DataGridTextColumn Header="End Time" Binding="{Binding EndTime}" Width="140" IsReadOnly="True"/>
                                        <DataGridTextColumn Header="Duration" Binding="{Binding Duration}" Width="85" IsReadOnly="True"/>
                                    </DataGrid.Columns>
                                </DataGrid>
                            </Grid>
                        </Border>
                    </Grid>
                </Border>
            </Grid>
        </Grid>

        <!-- ROW 2: HORIZONTAL SPLITTER BETWEEN UPPER WORKSPACE AND DEPLOYMENT STATUS -->
        <GridSplitter x:Name="splitUpperStatus" Grid.Row="2" Height="6" HorizontalAlignment="Stretch" VerticalAlignment="Center"
                      Background="#313244" ResizeDirection="Rows" ResizeBehavior="PreviousAndNext"
                      ShowsPreview="False" Cursor="SizeNS"
                      ToolTip="Drag up or down to resize Upper Workspace and Deployment Status"/>

        <!-- ROW 3: DEPLOYMENT CONTROLS BAR + RESULTS DATAGRID -->
        <Grid Grid.Row="3">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="0,4,0,6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <CheckBox x:Name="chkContinueOnError" Grid.Column="0" Content="Continue on step failure (default: stop computer's remaining steps)"/>
                <Button x:Name="btnClearResultFilters" Grid.Column="1" Content="🧹 Clear Log Filters" Width="Auto" Height="30" Padding="10,2" Background="#45475A" Foreground="#CDD6F4" Margin="0,0,8,0" ToolTip="Clear all column header filters and sorting in the Status Log"/>
                <Button x:Name="btnDeleteRow" Grid.Column="2" Content="🗑 Delete Row" Width="Auto" Height="30" Padding="12,2" Background="#FAB387" Foreground="#11111B" Margin="0,0,8,0" ToolTip="Delete selected deployment result row"/>
                <Button x:Name="btnClearStatus" Grid.Column="3" Content="🧹 Clear Status" Width="Auto" Height="30" Padding="12,2" Background="#F38BA8" Foreground="#11111B" Margin="0,0,8,0" ToolTip="Clear all deployment result status rows"/>
                <Button x:Name="btnSaveLogs" Grid.Column="4" Content="💾 Export to CSV" Width="Auto" Height="30" Padding="12,2" Background="#89DCEB" Foreground="#11111B" Margin="0,0,8,0" ToolTip="Export deployment result status logs to a CSV file"/>
                <Button x:Name="btnStopDeploy" Grid.Column="5" Content="⏹ Stop Deployment" Width="Auto" Height="30" Padding="14,2" Background="#F38BA8" Foreground="#11111B" Margin="0" IsEnabled="False" ToolTip="Stop the currently running deployment"/>
            </Grid>

            <Border Grid.Row="1" Background="#181825" CornerRadius="6" Padding="5">
                <DataGrid x:Name="dgResults" AutoGenerateColumns="False" IsReadOnly="True" HeadersVisibility="Column" RowHeaderWidth="0"
                          Background="#181825" Foreground="#CDD6F4" RowBackground="#1E1E2E" AlternatingRowBackground="#313244"
                          GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#45475A" BorderThickness="0"
                          CanUserSortColumns="True" SelectionMode="Single"
                          ToolTip="Double-click any row to view full multi-step deployment details. Right-click a row to re-deploy or delete.">
                    <DataGrid.Columns>
                        <DataGridTextColumn Binding="{Binding ComputerName}" Width="145" CanUserSort="True" SortMemberPath="ComputerName">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Computer Name ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Computer Name"/>
                                        <Button x:Name="btnResultHeaderMenu_ComputerName" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Computer Name"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_ComputerName" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Computer Name"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding PackageName}" Width="145" CanUserSort="True" SortMemberPath="PackageName">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Package ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Package Name"/>
                                        <Button x:Name="btnResultHeaderMenu_PackageName" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Package"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_PackageName" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Package Name"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding Step}" Width="165" CanUserSort="True" SortMemberPath="Step">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Current / Last Step ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Current / Last Step"/>
                                        <Button x:Name="btnResultHeaderMenu_Step" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Current / Last Step"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_Step" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Step"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding Status}" Width="100" CanUserSort="True" SortMemberPath="Status">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Status ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Status"/>
                                        <Button x:Name="btnResultHeaderMenu_Status" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Status"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_Status" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Status (e.g. Success, Failed, Running)"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding StartTime}" Width="135" CanUserSort="True" SortMemberPath="StartTime">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Start Time ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Start Time"/>
                                        <Button x:Name="btnResultHeaderMenu_StartTime" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Start Time"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_StartTime" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Start Time"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding EndTime}" Width="135" CanUserSort="True" SortMemberPath="EndTime">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="End Time ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by End Time"/>
                                        <Button x:Name="btnResultHeaderMenu_EndTime" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for End Time"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_EndTime" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by End Time"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding Duration}" Width="105" CanUserSort="True" SortMemberPath="DurationSeconds">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Total Duration ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort numerically by Total Duration"/>
                                        <Button x:Name="btnResultHeaderMenu_Duration" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Total Duration"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_Duration" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Duration"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                        </DataGridTextColumn>
                        <DataGridTextColumn Binding="{Binding Details}" Width="*" CanUserSort="True" SortMemberPath="Details">
                            <DataGridTextColumn.Header>
                                <StackPanel Margin="0,1">
                                    <Grid Margin="0,0,0,3">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock Grid.Column="0" Text="Details ⇅" FontWeight="Bold" Foreground="#89B4FA" FontSize="11.5" VerticalAlignment="Center" ToolTip="Click header to sort by Details"/>
                                        <Button x:Name="btnResultHeaderMenu_Details" Grid.Column="1" Content="▾" Width="20" Height="18" Padding="0" FontSize="11" Background="#2B2E44" Foreground="#89B4FA" BorderBrush="#3D415B" Margin="4,0,0,0" ToolTip="Sort &amp; Filter options for Details"/>
                                    </Grid>
                                    <TextBox x:Name="txtFilterResult_Details" Height="21" FontSize="11" Padding="4,1" Background="#1E1E2E" Foreground="#CDD6F4" BorderBrush="#45475A" ToolTip="Type to filter Status Log by Details"/>
                                </StackPanel>
                            </DataGridTextColumn.Header>
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="TextWrapping" Value="Wrap"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </Border>
        </Grid>

        <!-- ROW 4: STATUSBAR -->
        <StatusBar Grid.Row="4" Background="Transparent" Margin="0,6,0,0">
            <TextBlock x:Name="lblStatus" Text="Ready." Foreground="#A6ADC8"/>
        </StatusBar>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Map Controls
$txtSingleComp          = $window.FindName("txtSingleComp")
$btnAddTargets          = $window.FindName("btnAddTargets")
$btnBrowseCSV           = $window.FindName("btnBrowseCSV")
$btnBrowseAD            = $window.FindName("btnBrowseAD")
$btnRefreshTargets      = $window.FindName("btnRefreshTargets")
$btnSelectAllTargets    = $window.FindName("btnSelectAllTargets")
$btnRemoveTarget        = $window.FindName("btnRemoveTarget")
$lblAdSyncStatusBadge   = $window.FindName("lblAdSyncStatusBadge")
$dgTargets              = $window.FindName("dgTargets")
$lblTargetCount         = $window.FindName("lblTargetCount")
$lblTargetCountDetail   = $window.FindName("lblTargetCountDetail")
$lblTargetOnlineCount   = $window.FindName("lblTargetOnlineCount")
$lblTargetOfflineCount  = $window.FindName("lblTargetOfflineCount")

$lblSettingsSummary     = $window.FindName("lblSettingsSummary")
$btnSettings            = $window.FindName("btnSettings")

# Create reusable Package Steps Builder Modal Window
[xml]$pkgStepsModalXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Package Steps Builder — Remote Deployment Console" Height="620" Width="980" MinHeight="450" MinWidth="720"
        WindowStartupLocation="CenterOwner" Background="#1E1E2E" Foreground="#CDD6F4" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#F5E0DC"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="Padding" Value="5,3"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#89B4FA"/>
            <Setter Property="Foreground" Value="#11111B"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.88"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#6C7086"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <ControlTemplate x:Key="ComboBoxToggleButtonTemplate" TargetType="ToggleButton">
            <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="24"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="1" Text="&#x25BC;" Foreground="#CDD6F4" FontSize="10" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Grid>
            </Border>
        </ControlTemplate>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#F5E0DC"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="6,3"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton"
                                          Template="{StaticResource ComboBoxToggleButtonTemplate}"
                                          Background="{TemplateBinding Background}"
                                          BorderBrush="{TemplateBinding BorderBrush}"
                                          BorderThickness="{TemplateBinding BorderThickness}"
                                          Focusable="False"
                                          IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                          ClickMode="Press"/>
                            <ContentPresenter Name="ContentSite"
                                              IsHitTestVisible="False"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="8,3,26,3"
                                              VerticalAlignment="Center"
                                              HorizontalAlignment="Left"/>
                            <TextBox x:Name="PART_EditableTextBox"
                                     Style="{x:Null}"
                                     HorizontalAlignment="Left"
                                     VerticalAlignment="Center"
                                     Margin="6,3,26,3"
                                     Focusable="True"
                                     Background="Transparent"
                                     Foreground="#F5E0DC"
                                     CaretBrush="#F5E0DC"
                                     BorderThickness="0"
                                     Visibility="Hidden"
                                     IsReadOnly="{TemplateBinding IsReadOnly}"/>
                            <Popup Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True"
                                   Focusable="False"
                                   PopupAnimation="Slide">
                                <Grid Name="DropDown"
                                      SnapsToDevicePixels="True"
                                      MinWidth="{TemplateBinding ActualWidth}"
                                      MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <Border x:Name="DropDownBorder" Background="#252538" BorderThickness="1" BorderBrush="#45475A" CornerRadius="6" Padding="2">
                                        <ScrollViewer Margin="2" SnapsToDevicePixels="True">
                                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsEditable" Value="True">
                                <Setter Property="IsTabStop" Value="False"/>
                                <Setter TargetName="PART_EditableTextBox" Property="Visibility" Value="Visible"/>
                                <Setter TargetName="ContentSite" Property="Visibility" Value="Hidden"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#252538"/>
            <Setter Property="Foreground" Value="#F5E0DC"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#2563EB"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#1E40AF"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="RowBackground" Value="#1E1E2E"/>
            <Setter Property="AlternatingRowBackground" Value="#252538"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#313244"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#11111B"/>
            <Setter Property="Foreground" Value="#89B4FA"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="BorderBrush" Value="#313244"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>
        <Style TargetType="DataGridRow">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#2563EB"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#2A2B3D"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGridCell">
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="4,2"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#2563EB"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="📦 PACKAGE STEPS BUILDER (steps run in order on every target computer)" FontWeight="Bold" Foreground="#89B4FA" FontSize="14" Margin="0,0,0,10"/>
        <WrapPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,8">
            <TextBlock Text="Package Name:" Margin="0,0,6,4"/>
            <TextBox x:Name="txtPkgName" Width="260" Height="28" Text="Custom Deployment Package" Margin="0,0,14,4" ToolTip="Name of this deployment package"/>
            <TextBlock Text="Library Folder:" Margin="0,0,6,4"/>
            <ComboBox x:Name="txtPkgFolder" Width="170" Height="28" IsEditable="True" Text="General" Margin="0,0,0,4" ToolTip="Select an existing library folder or type a new folder name">
                <ComboBoxItem IsSelected="True">General</ComboBoxItem>
                <ComboBoxItem>Software</ComboBoxItem>
                <ComboBoxItem>Scripts</ComboBoxItem>
                <ComboBoxItem>Maintenance</ComboBoxItem>
            </ComboBox>
        </WrapPanel>
        <WrapPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,8">
            <Button x:Name="btnAddScript" Content="＋ PowerShell" Background="#89B4FA" Padding="10,5" Margin="0,0,6,4"/>
            <Button x:Name="btnAddBatch" Content="＋ Batch / CMD" Background="#FAB387" Padding="10,5" Margin="0,0,6,4" ToolTip="Add a native Windows Batch (.bat / .cmd) script step"/>
            <Button x:Name="btnCannedScripts" Content="📚 Canned-Scripts" Background="#F9E2AF" Padding="10,5" Margin="0,0,6,4" ToolTip="Browse pre-built Windows SysAdmin &amp; IT Troubleshooting PowerShell &amp; Batch scripts"/>
            <Button x:Name="btnAddInstaller" Content="＋ Installer" Background="#CBA6F7" Padding="10,5" Margin="0,0,6,4"/>
            <Button x:Name="btnAddPause" Content="⏱ Pause" Background="#94E2D5" Padding="10,5" Margin="0,0,6,4" ToolTip="Insert a timed wait/delay step between package steps"/>
            <Button x:Name="btnClearSteps" Content="🧹 Clear Steps" Background="#F38BA8" Padding="10,5" Margin="0,0,0,4" ToolTip="Remove all steps from the current package"/>
        </WrapPanel>
        <DataGrid x:Name="dgSteps" Grid.Row="3" AutoGenerateColumns="False" CanUserAddRows="False"
                  SelectionMode="Single" IsReadOnly="True" RowHeight="28">
            <DataGrid.ContextMenu>
                <ContextMenu>
                    <MenuItem x:Name="menuEditStep" Header="Edit Step..." InputGestureText="Double-Click"/>
                    <MenuItem x:Name="menuRenameStep" Header="Rename Task / Step..." InputGestureText="F2"/>
                    <MenuItem x:Name="menuMoveUp" Header="Move Step Up"/>
                    <MenuItem x:Name="menuMoveDown" Header="Move Step Down"/>
                    <Separator Background="#383A4E" Height="1" Margin="6,4"/>
                    <MenuItem x:Name="menuRemoveStep" Header="Remove Step" Foreground="#F38BA8"/>
                    <MenuItem x:Name="menuClearSteps" Header="Clear All Steps" Foreground="#F38BA8"/>
                </ContextMenu>
            </DataGrid.ContextMenu>
            <DataGrid.Columns>
                <DataGridTextColumn Header="#" Binding="{Binding Order}" Width="35"/>
                <DataGridTextColumn Header="Step Name" Binding="{Binding Name}" Width="210"/>
                <DataGridTextColumn Header="Type" Binding="{Binding Type}" Width="90"/>
                <DataGridTextColumn Header="Parameters" Binding="{Binding Parameters}" Width="160"/>
                <DataGridTextColumn Header="Summary" Binding="{Binding Summary}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>
        <DockPanel Grid.Row="4" Margin="0,12,0,0">
            <TextBlock Text="Tip: Double-click any step to edit its script or payload. Click '💾 Save to Library' to persist changes." Foreground="#A6ADC8" FontSize="11.5" VerticalAlignment="Center"/>
            <Button x:Name="btnSaveToLibrary" Content="💾 Save to Library" Width="145" Height="30" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" HorizontalAlignment="Right" DockPanel.Dock="Right" ToolTip="Save this package under the specified folder in the Package Library"/>
        </DockPanel>
    </Grid>
</Window>
"@
$pkgStepsModalReader = New-Object System.Xml.XmlNodeReader $pkgStepsModalXaml
$script:PkgStepsModalWindow = [System.Windows.Markup.XamlReader]::Load($pkgStepsModalReader)
$script:AppIsClosing = $false
$script:PkgStepsModalWindow.Add_Closing({
    if (-not $script:AppIsClosing) {
        $_.Cancel = $true
        $script:PkgStepsModalWindow.Hide()
        if (Get-Command Update-ActivePackageBanner -ErrorAction SilentlyContinue) {
            Update-ActivePackageBanner
        }
    }
})

$btnNewPkg              = $window.FindName("btnNewPkg")
$btnNewFolder           = $window.FindName("btnNewFolder")
$btnDeletePkg           = $window.FindName("btnDeletePkg")
$tvLibrary              = $window.FindName("tvLibrary")
$menuLibEditSteps       = $window.FindName("menuLibEditSteps")
$menuLibNewFolder       = $window.FindName("menuLibNewFolder")
$menuLibSaveHere        = $window.FindName("menuLibSaveHere")
$menuLibRename          = $window.FindName("menuLibRename")
$menuLibImport          = $window.FindName("menuLibImport")
$menuLibExport          = $window.FindName("menuLibExport")
$menuLibDelete          = $window.FindName("menuLibDelete")
# Main Window Deployment Panel Controls
$lblDeployActivePkg     = $window.FindName("lblDeployActivePkg")
$lblDeployRunningBadge  = $window.FindName("lblDeployRunningBadge")
$btnSelectAllDeployPkgs = $window.FindName("btnSelectAllDeployPkgs")
$btnOpenStepsModal      = $window.FindName("btnOpenStepsModal")
$btnDeployCheckedPkgs   = $window.FindName("btnDeployCheckedPkgs")
$btnDeployActiveNow     = $window.FindName("btnDeployActiveNow")
$dgDeployPackages       = $window.FindName("dgDeployPackages")
$dgDeployPreviewSteps   = $window.FindName("dgDeployPreviewSteps")

# Package Steps Builder Modal Controls
$txtPkgName             = $script:PkgStepsModalWindow.FindName("txtPkgName")
$txtPkgFolder           = $script:PkgStepsModalWindow.FindName("txtPkgFolder")
$btnSaveToLibrary       = $script:PkgStepsModalWindow.FindName("btnSaveToLibrary")

$btnAddScript           = $script:PkgStepsModalWindow.FindName("btnAddScript")
$btnAddBatch            = $script:PkgStepsModalWindow.FindName("btnAddBatch")
$btnCannedScripts       = $script:PkgStepsModalWindow.FindName("btnCannedScripts")
$btnAddInstaller        = $script:PkgStepsModalWindow.FindName("btnAddInstaller")
$btnAddPause            = $script:PkgStepsModalWindow.FindName("btnAddPause")
$btnClearSteps          = $script:PkgStepsModalWindow.FindName("btnClearSteps")
$dgSteps                = $script:PkgStepsModalWindow.FindName("dgSteps")
$btnCloseStepsModal     = $script:PkgStepsModalWindow.FindName("btnCloseStepsModal")
if ($btnCloseStepsModal) {
    $btnCloseStepsModal.Add_Click({
        $script:PkgStepsModalWindow.Hide()
        if (Get-Command Update-ActivePackageBanner -ErrorAction SilentlyContinue) {
            Update-ActivePackageBanner
        }
    })
}

$menuEditStep           = $script:PkgStepsModalWindow.FindName("menuEditStep")
$menuRenameStep         = $script:PkgStepsModalWindow.FindName("menuRenameStep")
$menuMoveUp             = $script:PkgStepsModalWindow.FindName("menuMoveUp")
$menuMoveDown           = $script:PkgStepsModalWindow.FindName("menuMoveDown")
$menuRemoveStep         = $script:PkgStepsModalWindow.FindName("menuRemoveStep")
$menuClearSteps         = $script:PkgStepsModalWindow.FindName("menuClearSteps")

$chkContinueOnError     = $window.FindName("chkContinueOnError")
$btnDeleteRow           = $window.FindName("btnDeleteRow")
$btnClearStatus         = $window.FindName("btnClearStatus")
$btnSaveLogs            = $window.FindName("btnSaveLogs")
$btnStopDeploy          = $window.FindName("btnStopDeploy")
$btnStart               = $window.FindName("btnStart")

$script:IsDeploymentRunning       = $false
$script:CancelDeploymentRequested = $false
$script:CurrentDeployJob          = $null
$dgResults              = $window.FindName("dgResults")
$lblStatus              = $window.FindName("lblStatus")
$lblStatusSummary       = $lblStatus

# Layout & Splitter Controls (Persistent Sizing)
$rowUpperWorkspace      = $window.FindName("rowUpperWorkspace")
$rowStatusLog           = $window.FindName("rowStatusLog")
$colPackageLibrary      = $window.FindName("colPackageLibrary")
$colRightStack          = $window.FindName("colRightStack")
$rowTargetComputers     = $window.FindName("rowTargetComputers")
$rowPackageSteps        = $window.FindName("rowPackageSteps")
$splitLibraryRight      = $window.FindName("splitLibraryRight")
$splitTargetsSteps      = $window.FindName("splitTargetsSteps")
$splitUpperStatus       = $window.FindName("splitUpperStatus")

# Computer Inventory Column Filter & Menu Controls
$cmbFilterTarget_Selected        = $window.FindName("cmbFilterTarget_Selected")
$txtFilterTarget_ComputerName    = $window.FindName("txtFilterTarget_ComputerName")
$txtFilterTarget_OnlineStatus    = $window.FindName("txtFilterTarget_OnlineStatus")
$txtFilterTarget_IPAddress       = $window.FindName("txtFilterTarget_IPAddress")
$txtFilterTarget_LogonUser       = $window.FindName("txtFilterTarget_LogonUser")
$txtFilterTarget_OUPath          = $window.FindName("txtFilterTarget_OUPath")
$txtFilterTarget_ADLastLogon     = $window.FindName("txtFilterTarget_ADLastLogon")
$btnClearTargetFilters           = $window.FindName("btnClearTargetFilters")
$btnTargetHeaderMenu_Selected     = $window.FindName("btnTargetHeaderMenu_Selected")
$btnTargetHeaderMenu_ComputerName = $window.FindName("btnTargetHeaderMenu_ComputerName")
$btnTargetHeaderMenu_OnlineStatus = $window.FindName("btnTargetHeaderMenu_OnlineStatus")
$btnTargetHeaderMenu_IPAddress    = $window.FindName("btnTargetHeaderMenu_IPAddress")
$btnTargetHeaderMenu_LogonUser    = $window.FindName("btnTargetHeaderMenu_LogonUser")
$btnTargetHeaderMenu_OUPath       = $window.FindName("btnTargetHeaderMenu_OUPath")
$btnTargetHeaderMenu_ADLastLogon  = $window.FindName("btnTargetHeaderMenu_ADLastLogon")

# Status Log Column Filter & Menu Controls
$txtFilterResult_ComputerName   = $window.FindName("txtFilterResult_ComputerName")
$txtFilterResult_PackageName    = $window.FindName("txtFilterResult_PackageName")
$txtFilterResult_Step           = $window.FindName("txtFilterResult_Step")
$txtFilterResult_Status         = $window.FindName("txtFilterResult_Status")
$txtFilterResult_StartTime      = $window.FindName("txtFilterResult_StartTime")
$txtFilterResult_EndTime        = $window.FindName("txtFilterResult_EndTime")
$txtFilterResult_Duration       = $window.FindName("txtFilterResult_Duration")
$txtFilterResult_Details        = $window.FindName("txtFilterResult_Details")
$btnClearResultFilters          = $window.FindName("btnClearResultFilters")
$btnResultHeaderMenu_ComputerName = $window.FindName("btnResultHeaderMenu_ComputerName")
$btnResultHeaderMenu_PackageName  = $window.FindName("btnResultHeaderMenu_PackageName")
$btnResultHeaderMenu_Step         = $window.FindName("btnResultHeaderMenu_Step")
$btnResultHeaderMenu_Status       = $window.FindName("btnResultHeaderMenu_Status")
$btnResultHeaderMenu_StartTime    = $window.FindName("btnResultHeaderMenu_StartTime")
$btnResultHeaderMenu_EndTime      = $window.FindName("btnResultHeaderMenu_EndTime")
$btnResultHeaderMenu_Duration     = $window.FindName("btnResultHeaderMenu_Duration")
$btnResultHeaderMenu_Details      = $window.FindName("btnResultHeaderMenu_Details")

# Collections
$script:StepsCollection = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
$dgSteps.ItemsSource = $script:StepsCollection
if ($dgDeployPreviewSteps) {
    $dgDeployPreviewSteps.ItemsSource = $script:StepsCollection
}
$script:DeployPackagesCollection = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
if ($dgDeployPackages) {
    $dgDeployPackages.ItemsSource = $script:DeployPackagesCollection
}

$script:TargetsCollection = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
$dgTargets.ItemsSource = $script:TargetsCollection

$script:ResultsCollection = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
$dgResults.ItemsSource = $script:ResultsCollection

function Test-ColumnTextFilterMatch {
    param(
        [AllowNull()][string]$CellValue,
        [AllowNull()][string]$FilterText
    )
    if ([string]::IsNullOrWhiteSpace($FilterText)) { return $true }
    $rawFilter = $FilterText.Trim()
    $val = if ($null -ne $CellValue) { [string]$CellValue } else { "" }
    if ($rawFilter -eq '=(Blank)') {
        return [string]::IsNullOrWhiteSpace($val)
    }
    if ($rawFilter.StartsWith('=')) {
        $exactTarget = $rawFilter.Substring(1)
        return ($val -ieq $exactTarget)
    }
    if ($rawFilter.Contains('|')) {
        $parts = @($rawFilter -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
        if ($parts.Count -gt 0) {
            foreach ($p in $parts) {
                if ($p -eq '(Blank)' -and [string]::IsNullOrWhiteSpace($val)) { return $true }
                if ($val.IndexOf($p, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
            }
            return $false
        }
    }
    return ($val.IndexOf($rawFilter, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
}

function Test-TargetDataColumnFilterActive {
    if ($txtFilterTarget_ComputerName -and -not [string]::IsNullOrWhiteSpace($txtFilterTarget_ComputerName.Text)) { return $true }
    if ($txtFilterTarget_OnlineStatus -and -not [string]::IsNullOrWhiteSpace($txtFilterTarget_OnlineStatus.Text)) { return $true }
    if ($txtFilterTarget_IPAddress -and -not [string]::IsNullOrWhiteSpace($txtFilterTarget_IPAddress.Text)) { return $true }
    if ($txtFilterTarget_LogonUser -and -not [string]::IsNullOrWhiteSpace($txtFilterTarget_LogonUser.Text)) { return $true }
    if ($txtFilterTarget_OUPath -and -not [string]::IsNullOrWhiteSpace($txtFilterTarget_OUPath.Text)) { return $true }
    if ($txtFilterTarget_ADLastLogon -and -not [string]::IsNullOrWhiteSpace($txtFilterTarget_ADLastLogon.Text)) { return $true }
    return $false
}

function Test-TargetDataColumnFilterMatch {
    param($Item)
    if ($null -eq $Item) { return $false }
    if ($txtFilterTarget_ComputerName -and -not (Test-ColumnTextFilterMatch -CellValue $Item.ComputerName -FilterText $txtFilterTarget_ComputerName.Text)) { return $false }
    if ($txtFilterTarget_OnlineStatus -and -not (Test-ColumnTextFilterMatch -CellValue $Item.OnlineStatus -FilterText $txtFilterTarget_OnlineStatus.Text)) { return $false }
    if ($txtFilterTarget_IPAddress -and -not (Test-ColumnTextFilterMatch -CellValue $Item.IPAddress -FilterText $txtFilterTarget_IPAddress.Text)) { return $false }
    if ($txtFilterTarget_LogonUser -and -not (Test-ColumnTextFilterMatch -CellValue $Item.LogonUser -FilterText $txtFilterTarget_LogonUser.Text)) { return $false }
    if ($txtFilterTarget_OUPath -and -not (Test-ColumnTextFilterMatch -CellValue $Item.OUPath -FilterText $txtFilterTarget_OUPath.Text)) { return $false }
    if ($txtFilterTarget_ADLastLogon -and -not (Test-ColumnTextFilterMatch -CellValue $Item.ADLastLogon -FilterText $txtFilterTarget_ADLastLogon.Text)) { return $false }
    return $true
}

function Test-TargetFilterActive {
    $selMode = if ($cmbFilterTarget_Selected -and $cmbFilterTarget_Selected.SelectedItem) {
        if ($cmbFilterTarget_Selected.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) {
            [string]$cmbFilterTarget_Selected.SelectedItem.Content
        } else {
            [string]$cmbFilterTarget_Selected.SelectedItem
        }
    } else { "All" }
    if ($selMode -ne "All") { return $true }
    return (Test-TargetDataColumnFilterActive)
}

function Test-TargetItemFilter {
    param($Item)
    if ($null -eq $Item) { return $false }

    if ($cmbFilterTarget_Selected -and $cmbFilterTarget_Selected.SelectedItem) {
        $selText = if ($cmbFilterTarget_Selected.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) {
            [string]$cmbFilterTarget_Selected.SelectedItem.Content
        } else {
            [string]$cmbFilterTarget_Selected.SelectedItem
        }
        if ($selText -eq "Checked" -and (-not [bool]$Item.Selected)) { return $false }
        if ($selText -eq "Unchecked" -and ([bool]$Item.Selected)) { return $false }
    }

    if (-not (Test-TargetDataColumnFilterMatch -Item $Item)) { return $false }

    return $true
}

function Test-ResultItemFilter {
    param($Item)
    if ($null -eq $Item) { return $false }

    # Only display computer status rows when a deployment task is selected in the DEPLOYMENT panel
    if (-not $dgDeployPackages -or $null -eq $dgDeployPackages.SelectedItem) {
        return $false
    }
    $selDeploy = $dgDeployPackages.SelectedItem
    if ($selDeploy.PSObject.Properties['DeploymentId'] -and -not [string]::IsNullOrWhiteSpace([string]$selDeploy.DeploymentId)) {
        $itemDepId = if ($Item.PSObject.Properties['DeploymentId']) { [string]$Item.DeploymentId } else { "" }
        if ($itemDepId -ne [string]$selDeploy.DeploymentId) {
            return $false
        }
    }

    if ($txtFilterResult_ComputerName -and -not (Test-ColumnTextFilterMatch -CellValue $Item.ComputerName -FilterText $txtFilterResult_ComputerName.Text)) { return $false }
    if ($txtFilterResult_PackageName -and -not (Test-ColumnTextFilterMatch -CellValue $Item.PackageName -FilterText $txtFilterResult_PackageName.Text)) { return $false }
    if ($txtFilterResult_Step -and -not (Test-ColumnTextFilterMatch -CellValue $Item.Step -FilterText $txtFilterResult_Step.Text)) { return $false }
    if ($txtFilterResult_Status -and -not (Test-ColumnTextFilterMatch -CellValue $Item.Status -FilterText $txtFilterResult_Status.Text)) { return $false }
    if ($txtFilterResult_StartTime -and -not (Test-ColumnTextFilterMatch -CellValue $Item.StartTime -FilterText $txtFilterResult_StartTime.Text)) { return $false }
    if ($txtFilterResult_EndTime -and -not (Test-ColumnTextFilterMatch -CellValue $Item.EndTime -FilterText $txtFilterResult_EndTime.Text)) { return $false }
    if ($txtFilterResult_Duration -and -not (Test-ColumnTextFilterMatch -CellValue $Item.Duration -FilterText $txtFilterResult_Duration.Text)) { return $false }
    if ($txtFilterResult_Details -and -not (Test-ColumnTextFilterMatch -CellValue $Item.Details -FilterText $txtFilterResult_Details.Text)) { return $false }

    return $true
}

$script:TargetsCollectionView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dgTargets.ItemsSource)
if ($script:TargetsCollectionView) {
    $script:TargetsCollectionView.Filter = [Predicate[object]]{
        param($row)
        return (Test-TargetItemFilter -Item $row)
    }
}

$script:ResultsCollectionView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dgResults.ItemsSource)
if ($script:ResultsCollectionView) {
    $script:ResultsCollectionView.Filter = [Predicate[object]]{
        param($row)
        return (Test-ResultItemFilter -Item $row)
    }
}

function Update-TargetCountSummary {
    $total = if ($null -ne $script:TargetsCollection) { $script:TargetsCollection.Count } else { 0 }
    $checked = if ($total -gt 0) { @($script:TargetsCollection | Where-Object { [bool]$_.Selected }).Count } else { 0 }
    $onlineCount = if ($total -gt 0) { @($script:TargetsCollection | Where-Object { $_.OnlineStatus -eq 'Online' }).Count } else { 0 }
    $offlineCount = if ($total -gt 0) { @($script:TargetsCollection | Where-Object { $_.OnlineStatus -eq 'Offline' }).Count } else { 0 }
    if ($lblTargetCount) {
        $lblTargetCount.Text = "$checked/$total"
    }
    if ($lblTargetOnlineCount) {
        $lblTargetOnlineCount.Text = "$onlineCount"
    }
    if ($lblTargetOfflineCount) {
        $lblTargetOfflineCount.Text = "$offlineCount"
    }
    if ($lblTargetCountDetail) {
        if (Test-TargetFilterActive) {
            $visibleCount = if ($total -gt 0) { @($script:TargetsCollection | Where-Object { Test-TargetItemFilter -Item $_ }).Count } else { 0 }
            $lblTargetCountDetail.Text = " ($checked checked of $total imported | showing $visibleCount filtered)"
        } else {
            $lblTargetCountDetail.Text = " ($checked checked of $total imported)"
        }
    }
}

function Invoke-RefreshTargetsFilter {
    try {
        [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
        [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true)
    } catch {}
    if ($null -ne $script:TargetsCollection -and (Test-TargetDataColumnFilterActive)) {
        foreach ($item in $script:TargetsCollection) {
            if ($null -ne $item -and (-not (Test-TargetDataColumnFilterMatch -Item $item)) -and [bool]$item.Selected) {
                $item.Selected = $false
            }
        }
    }
    if ($script:TargetsCollectionView) {
        try { $script:TargetsCollectionView.Refresh() } catch {}
    }
    if ($dgTargets) {
        try { $dgTargets.Items.Refresh() } catch {}
    }
    Update-TargetCountSummary
}

function Invoke-RefreshResultsFilter {
    try {
        [void]$dgResults.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
        [void]$dgResults.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true)
    } catch {}
    if ($script:ResultsCollectionView) {
        try { $script:ResultsCollectionView.Refresh() } catch {}
    }
}

function Clear-AllTargetColumnFilters {
    if ($cmbFilterTarget_Selected) { $cmbFilterTarget_Selected.SelectedIndex = 0 }
    foreach ($tb in @($txtFilterTarget_ComputerName, $txtFilterTarget_OnlineStatus, $txtFilterTarget_IPAddress, $txtFilterTarget_LogonUser, $txtFilterTarget_OUPath, $txtFilterTarget_ADLastLogon)) {
        if ($tb) { $tb.Text = "" }
    }
    Invoke-RefreshTargetsFilter
}

function Clear-AllResultColumnFilters {
    foreach ($tb in @($txtFilterResult_ComputerName, $txtFilterResult_PackageName, $txtFilterResult_Step, $txtFilterResult_Status, $txtFilterResult_StartTime, $txtFilterResult_EndTime, $txtFilterResult_Duration, $txtFilterResult_Details)) {
        if ($tb) { $tb.Text = "" }
    }
    Invoke-RefreshResultsFilter
}
Set-Alias -Name Clear-AllResultFilters -Value Clear-AllResultColumnFilters -Scope Script

function Set-DataGridColumnSort {
    param(
        [System.Windows.Controls.DataGrid]$DataGrid,
        [string]$SortProperty,
        [ValidateSet("Ascending", "Descending", "Clear")][string]$Direction = "Ascending"
    )
    if (-not $DataGrid -or -not $DataGrid.ItemsSource) { return }
    try {
        [void]$DataGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
        [void]$DataGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true)
    } catch {}
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($DataGrid.ItemsSource)
    if (-not $view) { return }
    $view.SortDescriptions.Clear()
    foreach ($col in $DataGrid.Columns) {
        $col.SortDirection = $null
    }
    if ($Direction -ne "Clear" -and -not [string]::IsNullOrWhiteSpace($SortProperty)) {
        $listDir = if ($Direction -eq "Descending") {
            [System.ComponentModel.ListSortDirection]::Descending
        } else {
            [System.ComponentModel.ListSortDirection]::Ascending
        }
        $view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription($SortProperty, $listDir)))
        foreach ($col in $DataGrid.Columns) {
            if ($col.SortMemberPath -eq $SortProperty) {
                $col.SortDirection = $listDir
            }
        }
    }
    try { $view.Refresh() } catch {}
}

function New-Win11MenuIcon {
    param(
        [string]$Glyph,
        [string]$ColorHex = "#89B4FA"
    )
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Glyph
    $tb.FontSize = 12
    $tb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $tb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ColorHex)
    return $tb
}

function New-Win11ContextMenu {
    param([System.Windows.UIElement]$PlacementTarget = $null)
    $ctx = New-Object System.Windows.Controls.ContextMenu
    if ($window -and $window.Resources) {
        $ctxStyle = $window.Resources[[System.Windows.Controls.ContextMenu]]
        if ($ctxStyle) { $ctx.Style = $ctxStyle }
        foreach ($resType in @([System.Windows.Controls.MenuItem], [System.Windows.Controls.Separator], [System.Windows.Controls.Button], [System.Windows.Controls.TextBlock])) {
            $st = $window.Resources[$resType]
            if ($st -and -not $ctx.Resources.Contains($resType)) { [void]$ctx.Resources.Add($resType, $st) }
        }
    }
    if ($PlacementTarget) {
        $ctx.PlacementTarget = $PlacementTarget
        $ctx.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
    }
    return $ctx
}

function New-Win11QuickActionButton {
    param(
        [string]$Glyph,
        [string]$Label,
        [string]$GlyphColor = "#89B4FA",
        [string]$ToolTipText = "",
        [scriptblock]$OnClick
    )
    $btn = New-Object System.Windows.Controls.Button
    $btn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#282B3E")
    $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#383C54")
    $btn.BorderThickness = New-Object System.Windows.Thickness(1)
    $btn.Padding = New-Object System.Windows.Thickness(8, 5, 8, 5)
    $btn.Margin = New-Object System.Windows.Thickness(2, 1, 2, 1)
    $btn.MinWidth = 60
    $btn.Height = [Double]::NaN
    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
    if ($ToolTipText) { $btn.ToolTip = $ToolTipText }

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = [System.Windows.Controls.Orientation]::Vertical
    $sp.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    $tbIcon = New-Object System.Windows.Controls.TextBlock
    $tbIcon.Text = $Glyph
    $tbIcon.FontSize = 13
    $tbIcon.FontWeight = [System.Windows.FontWeights]::Bold
    $tbIcon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $tbIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($GlyphColor)
    [void]$sp.Children.Add($tbIcon)

    $tbLbl = New-Object System.Windows.Controls.TextBlock
    $tbLbl.Text = $Label
    $tbLbl.FontSize = 10.5
    $tbLbl.Margin = New-Object System.Windows.Thickness(0, 2, 0, 0)
    $tbLbl.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $tbLbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CDD6F4")
    [void]$sp.Children.Add($tbLbl)

    $btn.Content = $sp
    if ($OnClick) { $btn.Add_Click($OnClick) }
    return $btn
}

function Show-ColumnHeaderSortFilterMenu {
    param(
        [System.Windows.Controls.Button]$AnchorButton,
        [System.Windows.Controls.DataGrid]$DataGrid,
        [string]$ColumnTitle,
        [string]$SortProperty,
        [string]$ValueProperty,
        [System.Windows.Controls.Control]$FilterControl,
        [scriptblock]$RefreshCallback,
        [scriptblock]$ClearAllCallback
    )
    if (-not $AnchorButton -or -not $DataGrid) { return }

    $ctx = New-Win11ContextMenu -PlacementTarget $AnchorButton

    # Windows 11 Top Quick-Action Icon Bar (Sort A-Z | Sort Z-A | Clear Col | Reset All)
    $quickBarHost = New-Object System.Windows.Controls.MenuItem
    $quickBarHost.StaysOpenOnClick = $true
    $quickBarHost.Padding = New-Object System.Windows.Thickness(2, 2, 2, 2)

    $quickBarPanel = New-Object System.Windows.Controls.StackPanel
    $quickBarPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $quickBarPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    $btnQAsc = New-Win11QuickActionButton -Glyph "↑" -Label "Sort A-Z" -GlyphColor "#89B4FA" -ToolTipText "Sort $ColumnTitle Ascending"
    $btnQAsc.Add_Click(({
        $ctx.IsOpen = $false
        Set-DataGridColumnSort -DataGrid $DataGrid -SortProperty $SortProperty -Direction "Ascending"
    }).GetNewClosure())
    [void]$quickBarPanel.Children.Add($btnQAsc)

    $btnQDesc = New-Win11QuickActionButton -Glyph "↓" -Label "Sort Z-A" -GlyphColor "#CBA6F7" -ToolTipText "Sort $ColumnTitle Descending"
    $btnQDesc.Add_Click(({
        $ctx.IsOpen = $false
        Set-DataGridColumnSort -DataGrid $DataGrid -SortProperty $SortProperty -Direction "Descending"
    }).GetNewClosure())
    [void]$quickBarPanel.Children.Add($btnQDesc)

    $btnQClearCol = New-Win11QuickActionButton -Glyph "🧹" -Label "Clear Col" -GlyphColor "#F9E2AF" -ToolTipText "Clear filter on $ColumnTitle"
    $btnQClearCol.Add_Click(({
        $ctx.IsOpen = $false
        if ($FilterControl -is [System.Windows.Controls.ComboBox]) {
            $FilterControl.SelectedIndex = 0
        } elseif ($FilterControl -is [System.Windows.Controls.TextBox]) {
            $FilterControl.Text = ""
        }
        if ($RefreshCallback) { & $RefreshCallback }
    }).GetNewClosure())
    [void]$quickBarPanel.Children.Add($btnQClearCol)

    $btnQResetAll = New-Win11QuickActionButton -Glyph "🔄" -Label "Reset All" -GlyphColor "#F38BA8" -ToolTipText "Clear all column filters"
    $btnQResetAll.Add_Click(({
        $ctx.IsOpen = $false
        if ($ClearAllCallback) { & $ClearAllCallback }
    }).GetNewClosure())
    [void]$quickBarPanel.Children.Add($btnQResetAll)

    $quickBarHost.Header = $quickBarPanel
    [void]$ctx.Items.Add($quickBarHost)
    [void]$ctx.Items.Add((New-Object System.Windows.Controls.Separator))

    $miAsc = New-Object System.Windows.Controls.MenuItem
    $miAsc.Header = "Sort Ascending ($ColumnTitle)"
    $miAsc.InputGestureText = "A→Z"
    $miAsc.Icon = New-Win11MenuIcon -Glyph "↑" -ColorHex "#89B4FA"
    $miAsc.Add_Click(({
        Set-DataGridColumnSort -DataGrid $DataGrid -SortProperty $SortProperty -Direction "Ascending"
    }).GetNewClosure())
    [void]$ctx.Items.Add($miAsc)

    $miDesc = New-Object System.Windows.Controls.MenuItem
    $miDesc.Header = "Sort Descending ($ColumnTitle)"
    $miDesc.InputGestureText = "Z→A"
    $miDesc.Icon = New-Win11MenuIcon -Glyph "↓" -ColorHex "#CBA6F7"
    $miDesc.Add_Click(({
        Set-DataGridColumnSort -DataGrid $DataGrid -SortProperty $SortProperty -Direction "Descending"
    }).GetNewClosure())
    [void]$ctx.Items.Add($miDesc)

    $miClearSort = New-Object System.Windows.Controls.MenuItem
    $miClearSort.Header = "Clear Sort"
    $miClearSort.InputGestureText = "Default"
    $miClearSort.Icon = New-Win11MenuIcon -Glyph "⇅" -ColorHex "#A6ADC8"
    $miClearSort.Add_Click(({
        Set-DataGridColumnSort -DataGrid $DataGrid -SortProperty $SortProperty -Direction "Clear"
    }).GetNewClosure())
    [void]$ctx.Items.Add($miClearSort)

    [void]$ctx.Items.Add((New-Object System.Windows.Controls.Separator))

    $miClearColFilter = New-Object System.Windows.Controls.MenuItem
    $miClearColFilter.Header = "Clear Filter on '$ColumnTitle'"
    $miClearColFilter.InputGestureText = "Col"
    $miClearColFilter.Icon = New-Win11MenuIcon -Glyph "🧹" -ColorHex "#F9E2AF"
    $miClearColFilter.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F9E2AF")
    $miClearColFilter.Add_Click(({
        if ($FilterControl -is [System.Windows.Controls.ComboBox]) {
            $FilterControl.SelectedIndex = 0
        } elseif ($FilterControl -is [System.Windows.Controls.TextBox]) {
            $FilterControl.Text = ""
        }
        if ($RefreshCallback) { & $RefreshCallback }
    }).GetNewClosure())
    [void]$ctx.Items.Add($miClearColFilter)

    $miClearAll = New-Object System.Windows.Controls.MenuItem
    $miClearAll.Header = "Clear All Column Filters"
    $miClearAll.InputGestureText = "Reset"
    $miClearAll.Icon = New-Win11MenuIcon -Glyph "✕" -ColorHex "#F38BA8"
    $miClearAll.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F38BA8")
    $miClearAll.Add_Click(({
        if ($ClearAllCallback) { & $ClearAllCallback }
    }).GetNewClosure())
    [void]$ctx.Items.Add($miClearAll)

    # Populate distinct values from ItemsSource for quick 1-click filtering
    if ($DataGrid.ItemsSource -and -not [string]::IsNullOrWhiteSpace($ValueProperty)) {
        [void]$ctx.Items.Add((New-Object System.Windows.Controls.Separator))
        $miHeader = New-Object System.Windows.Controls.MenuItem
        $miHeader.Header = "Quick Filter by Value:"
        $miHeader.IsEnabled = $false
        $miHeader.Icon = New-Win11MenuIcon -Glyph "⚡" -ColorHex "#89B4FA"
        $miHeader.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#89B4FA")
        [void]$ctx.Items.Add($miHeader)

        if ($ValueProperty -eq "Selected" -and ($FilterControl -is [System.Windows.Controls.ComboBox])) {
            foreach ($opt in @("All", "Checked", "Unchecked")) {
                $miVal = New-Object System.Windows.Controls.MenuItem
                $miVal.Header = $opt
                $miVal.IsCheckable = $true
                $curSel = if ($FilterControl.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) { [string]$FilterControl.SelectedItem.Content } else { [string]$FilterControl.SelectedItem }
                $miVal.IsChecked = ($curSel -eq $opt)
                $miVal.InputGestureText = if ($miVal.IsChecked) { "Active" } else { "" }
                $miVal.Icon = New-Win11MenuIcon -Glyph "•" -ColorHex "#585B70"
                $miVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E8F0")
                $optCopy = $opt
                $miVal.Add_Click(({
                    switch ($optCopy) {
                        "All"       { $FilterControl.SelectedIndex = 0 }
                        "Checked"   { $FilterControl.SelectedIndex = 1 }
                        "Unchecked" { $FilterControl.SelectedIndex = 2 }
                    }
                    if ($RefreshCallback) { & $RefreshCallback }
                }).GetNewClosure())
                [void]$ctx.Items.Add($miVal)
            }
        } elseif ($FilterControl -is [System.Windows.Controls.TextBox]) {
            $uniqueVals = New-Object System.Collections.Generic.List[string]
            $hasBlank = $false
            foreach ($row in $DataGrid.ItemsSource) {
                if ($null -eq $row) { continue }
                $propVal = $row.PSObject.Properties[$ValueProperty]
                $strVal = if ($propVal -and $null -ne $propVal.Value) { ([string]$propVal.Value).Trim() } else { "" }
                if ([string]::IsNullOrWhiteSpace($strVal)) {
                    $hasBlank = $true
                } else {
                    if (-not $uniqueVals.Contains($strVal)) {
                        [void]$uniqueVals.Add($strVal)
                    }
                }
            }
            $sortedVals = @($uniqueVals | Sort-Object | Select-Object -First 30)
            $curFilterText = $FilterControl.Text.Trim()
            if ($hasBlank) {
                $miBlank = New-Object System.Windows.Controls.MenuItem
                $miBlank.Header = "(Blank)"
                $miBlank.IsCheckable = $true
                $miBlank.IsChecked = ($curFilterText -eq "=(Blank)")
                $miBlank.InputGestureText = if ($miBlank.IsChecked) { "Active" } else { "" }
                $miBlank.Icon = New-Win11MenuIcon -Glyph "•" -ColorHex "#585B70"
                $miBlank.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E8F0")
                $miBlank.Add_Click(({
                    if ($FilterControl.Text -eq "=(Blank)") {
                        $FilterControl.Text = ""
                    } else {
                        $FilterControl.Text = "=(Blank)"
                    }
                    if ($RefreshCallback) { & $RefreshCallback }
                }).GetNewClosure())
                [void]$ctx.Items.Add($miBlank)
            }
            foreach ($uv in $sortedVals) {
                $miVal = New-Object System.Windows.Controls.MenuItem
                $displayHeader = if ($uv.Length -gt 55) { $uv.Substring(0, 52) + "..." } else { $uv }
                $miVal.Header = $displayHeader.Replace("_", "__")
                $miVal.IsCheckable = $true
                $miVal.IsChecked = ($curFilterText -ieq "=$uv" -or $curFilterText -ieq $uv)
                $miVal.InputGestureText = if ($miVal.IsChecked) { "Active" } else { "" }
                $miVal.Icon = New-Win11MenuIcon -Glyph "•" -ColorHex "#585B70"
                $miVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E8F0")
                $uvCopy = $uv
                $miVal.Add_Click(({
                    if ($FilterControl.Text -ieq "=$uvCopy" -or $FilterControl.Text -ieq $uvCopy) {
                        $FilterControl.Text = ""
                    } else {
                        $FilterControl.Text = "=$uvCopy"
                    }
                    if ($RefreshCallback) { & $RefreshCallback }
                }).GetNewClosure())
                [void]$ctx.Items.Add($miVal)
            }
        }
    }

    $ctx.IsOpen = $true
}

# Wire up Target Computers filter events
if ($cmbFilterTarget_Selected) {
    $cmbFilterTarget_Selected.Add_SelectionChanged({ Invoke-RefreshTargetsFilter })
}
foreach ($tb in @($txtFilterTarget_ComputerName, $txtFilterTarget_OnlineStatus, $txtFilterTarget_IPAddress, $txtFilterTarget_LogonUser, $txtFilterTarget_OUPath, $txtFilterTarget_ADLastLogon)) {
    if ($tb) {
        $tb.Add_TextChanged({ Invoke-RefreshTargetsFilter })
    }
}
if ($btnClearTargetFilters) {
    $btnClearTargetFilters.Add_Click({ Clear-AllTargetColumnFilters })
}

# Wire up Status Log filter events
foreach ($tb in @($txtFilterResult_ComputerName, $txtFilterResult_PackageName, $txtFilterResult_Step, $txtFilterResult_Status, $txtFilterResult_StartTime, $txtFilterResult_EndTime, $txtFilterResult_Duration, $txtFilterResult_Details)) {
    if ($tb) {
        $tb.Add_TextChanged({ Invoke-RefreshResultsFilter })
    }
}
if ($btnClearResultFilters) {
    $btnClearResultFilters.Add_Click({ Clear-AllResultColumnFilters })
}

# Wire up Target Header Menu Buttons
if ($btnTargetHeaderMenu_Selected) {
    $btnTargetHeaderMenu_Selected.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_Selected -DataGrid $dgTargets -ColumnTitle "Deploy" -SortProperty "Selected" -ValueProperty "Selected" -FilterControl $cmbFilterTarget_Selected -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}
if ($btnTargetHeaderMenu_ComputerName) {
    $btnTargetHeaderMenu_ComputerName.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_ComputerName -DataGrid $dgTargets -ColumnTitle "Computer Name" -SortProperty "ComputerName" -ValueProperty "ComputerName" -FilterControl $txtFilterTarget_ComputerName -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}
if ($btnTargetHeaderMenu_OnlineStatus) {
    $btnTargetHeaderMenu_OnlineStatus.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_OnlineStatus -DataGrid $dgTargets -ColumnTitle "Online Status" -SortProperty "OnlineStatus" -ValueProperty "OnlineStatus" -FilterControl $txtFilterTarget_OnlineStatus -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}
if ($btnTargetHeaderMenu_IPAddress) {
    $btnTargetHeaderMenu_IPAddress.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_IPAddress -DataGrid $dgTargets -ColumnTitle "IP Address" -SortProperty "IPAddress" -ValueProperty "IPAddress" -FilterControl $txtFilterTarget_IPAddress -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}
if ($btnTargetHeaderMenu_LogonUser) {
    $btnTargetHeaderMenu_LogonUser.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_LogonUser -DataGrid $dgTargets -ColumnTitle "Current Logon User" -SortProperty "LogonUser" -ValueProperty "LogonUser" -FilterControl $txtFilterTarget_LogonUser -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}
if ($btnTargetHeaderMenu_OUPath) {
    $btnTargetHeaderMenu_OUPath.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_OUPath -DataGrid $dgTargets -ColumnTitle "AD OU Path" -SortProperty "OUPath" -ValueProperty "OUPath" -FilterControl $txtFilterTarget_OUPath -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}
if ($btnTargetHeaderMenu_ADLastLogon) {
    $btnTargetHeaderMenu_ADLastLogon.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnTargetHeaderMenu_ADLastLogon -DataGrid $dgTargets -ColumnTitle "AD Last Logon" -SortProperty "ADLastLogon" -ValueProperty "ADLastLogon" -FilterControl $txtFilterTarget_ADLastLogon -RefreshCallback ${function:Invoke-RefreshTargetsFilter} -ClearAllCallback ${function:Clear-AllTargetColumnFilters}
    })
}

# Wire up Status Log Header Menu Buttons
if ($btnResultHeaderMenu_ComputerName) {
    $btnResultHeaderMenu_ComputerName.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_ComputerName -DataGrid $dgResults -ColumnTitle "Computer Name" -SortProperty "ComputerName" -ValueProperty "ComputerName" -FilterControl $txtFilterResult_ComputerName -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_PackageName) {
    $btnResultHeaderMenu_PackageName.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_PackageName -DataGrid $dgResults -ColumnTitle "Deployment Package" -SortProperty "PackageName" -ValueProperty "PackageName" -FilterControl $txtFilterResult_PackageName -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_Step) {
    $btnResultHeaderMenu_Step.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_Step -DataGrid $dgResults -ColumnTitle "Current / Last Step" -SortProperty "Step" -ValueProperty "Step" -FilterControl $txtFilterResult_Step -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_Status) {
    $btnResultHeaderMenu_Status.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_Status -DataGrid $dgResults -ColumnTitle "Status" -SortProperty "Status" -ValueProperty "Status" -FilterControl $txtFilterResult_Status -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_StartTime) {
    $btnResultHeaderMenu_StartTime.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_StartTime -DataGrid $dgResults -ColumnTitle "Start Time" -SortProperty "StartTime" -ValueProperty "StartTime" -FilterControl $txtFilterResult_StartTime -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_EndTime) {
    $btnResultHeaderMenu_EndTime.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_EndTime -DataGrid $dgResults -ColumnTitle "End Time" -SortProperty "EndTime" -ValueProperty "EndTime" -FilterControl $txtFilterResult_EndTime -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_Duration) {
    $btnResultHeaderMenu_Duration.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_Duration -DataGrid $dgResults -ColumnTitle "Total Duration" -SortProperty "DurationSeconds" -ValueProperty "Duration" -FilterControl $txtFilterResult_Duration -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}
if ($btnResultHeaderMenu_Details) {
    $btnResultHeaderMenu_Details.Add_Click({
        param($sender, $e)
        $e.Handled = $true
        Show-ColumnHeaderSortFilterMenu -AnchorButton $btnResultHeaderMenu_Details -DataGrid $dgResults -ColumnTitle "Details" -SortProperty "Details" -ValueProperty "Details" -FilterControl $txtFilterResult_Details -RefreshCallback ${function:Invoke-RefreshResultsFilter} -ClearAllCallback ${function:Clear-AllResultColumnFilters}
    })
}

# Prevent clicks inside header filter controls or menu buttons from triggering DataGrid column sorting
$allHeaderInteractiveControls = @(
    $cmbFilterTarget_Selected,
    $txtFilterTarget_ComputerName, $txtFilterTarget_OnlineStatus, $txtFilterTarget_IPAddress, $txtFilterTarget_LogonUser, $txtFilterTarget_OUPath, $txtFilterTarget_ADLastLogon,
    $btnTargetHeaderMenu_Selected, $btnTargetHeaderMenu_ComputerName, $btnTargetHeaderMenu_OnlineStatus, $btnTargetHeaderMenu_IPAddress, $btnTargetHeaderMenu_LogonUser, $btnTargetHeaderMenu_OUPath, $btnTargetHeaderMenu_ADLastLogon,
    $txtFilterResult_ComputerName, $txtFilterResult_PackageName, $txtFilterResult_Step, $txtFilterResult_Status, $txtFilterResult_StartTime, $txtFilterResult_EndTime, $txtFilterResult_Duration, $txtFilterResult_Details,
    $btnResultHeaderMenu_ComputerName, $btnResultHeaderMenu_PackageName, $btnResultHeaderMenu_Step, $btnResultHeaderMenu_Status, $btnResultHeaderMenu_StartTime, $btnResultHeaderMenu_EndTime, $btnResultHeaderMenu_Duration, $btnResultHeaderMenu_Details
)

$dgTargets.Add_Sorting({
    param($sender, $e)
    foreach ($ctrl in $allHeaderInteractiveControls) {
        if ($ctrl -and ($ctrl.IsMouseOver -or $ctrl.IsKeyboardFocusWithin)) {
            $e.Handled = $true
            return
        }
    }
})

$dgResults.Add_Sorting({
    param($sender, $e)
    foreach ($ctrl in $allHeaderInteractiveControls) {
        if ($ctrl -and ($ctrl.IsMouseOver -or $ctrl.IsKeyboardFocusWithin)) {
            $e.Handled = $true
            return
        }
    }
})

$script:TargetsCollection.Add_CollectionChanged({
    Update-TargetCountSummary
})

$dgTargets.AddHandler(
    [System.Windows.Controls.Primitives.ToggleButton]::ClickEvent,
    [System.Windows.RoutedEventHandler]{
        param($sender, $e)
        if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
            $cb = [System.Windows.Controls.CheckBox]$e.OriginalSource
            if ($cb.DataContext -and $null -ne $cb.DataContext.PSObject.Properties['Selected']) {
                $dgTargets.SelectedItem = $cb.DataContext
                Update-TargetCountSummary
                if ($cmbFilterTarget_Selected -and $cmbFilterTarget_Selected.SelectedIndex -gt 0) {
                    Invoke-RefreshTargetsFilter
                }
            }
        }
    }
)

$dgTargets.Add_PreviewMouseLeftButtonUp({
    if ($window -and $window.Dispatcher) {
        [void]$window.Dispatcher.BeginInvoke([Action]{
            try {
                [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
                [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true)
            } catch {}
            Update-TargetCountSummary
        }, [System.Windows.Threading.DispatcherPriority]::Background)
    }
})

$dgTargets.Add_KeyUp({
    if ($window -and $window.Dispatcher) {
        [void]$window.Dispatcher.BeginInvoke([Action]{
            try {
                [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
                [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true)
            } catch {}
            Update-TargetCountSummary
        }, [System.Windows.Threading.DispatcherPriority]::Background)
    }
})

$dgTargets.Add_CellEditEnding({
    if ($window -and $window.Dispatcher) {
        [void]$window.Dispatcher.BeginInvoke([Action]{
            Update-TargetCountSummary
        }, [System.Windows.Threading.DispatcherPriority]::Background)
    }
})

$dgTargets.Add_CurrentCellChanged({
    Update-TargetCountSummary
})

Update-TargetCountSummary

# ==========================================
# 2. SETTINGS ENGINE
# ==========================================
$script:BootstrapDir = Join-Path $env:LOCALAPPDATA "PSDeploy"
if (-not (Test-Path $script:BootstrapDir)) {
    [void][System.IO.Directory]::CreateDirectory($script:BootstrapDir)
}
$script:BootstrapFilePath = Join-Path $script:BootstrapDir "bootstrap.json"

function Update-ConfigPaths {
    param([string]$Directory)
    if ([string]::IsNullOrWhiteSpace($Directory)) {
        $Directory = $script:BootstrapDir
    }
    if (-not (Test-Path $Directory)) {
        [void][System.IO.Directory]::CreateDirectory($Directory)
    }
    $script:SettingsDir = $Directory
    $script:SettingsFilePath = Join-Path $script:SettingsDir "settings.json"
    $script:LibraryPath = Join-Path $script:SettingsDir "package_library.json"
    $script:PackagesDir = Join-Path $script:SettingsDir "packages"
    if (-not (Test-Path $script:PackagesDir)) {
        [void][System.IO.Directory]::CreateDirectory($script:PackagesDir)
    }
    $script:StatusStateFilePath = Join-Path $script:SettingsDir "status_state.json"
    $script:InventoryFilePath = Join-Path $script:SettingsDir "computer_inventory.json"
    $script:AdSyncConfigFilePath = Join-Path $script:SettingsDir "ad_sync_config.json"
    $script:UiLayoutFilePath = Join-Path $script:SettingsDir "ui_layout.json"
    $script:BootstrapUiLayoutFilePath = Join-Path $script:BootstrapDir "ui_layout.json"
    $script:LogsDir = Join-Path $script:SettingsDir "logs"
    if (-not (Test-Path $script:LogsDir)) {
        [void][System.IO.Directory]::CreateDirectory($script:LogsDir)
    }
    $script:DiagLogFile = Join-Path $script:LogsDir 'psdeploy_diagnostic.log'
    if ($null -ne $script:AppSettings) {
        $script:AppSettings.ConfigDirectory = $script:SettingsDir
    }
}

$initDir = $script:BootstrapDir
if (Test-Path $script:BootstrapFilePath) {
    try {
        $bJson = [System.IO.File]::ReadAllText($script:BootstrapFilePath, [System.Text.Encoding]::UTF8)
        $bObj = ConvertFrom-Json -InputObject $bJson -ErrorAction Stop
        if ($bObj.ConfigDirectory) {
            if (-not (Test-Path $bObj.ConfigDirectory)) {
                [void][System.IO.Directory]::CreateDirectory($bObj.ConfigDirectory)
            }
            $initDir = [string]$bObj.ConfigDirectory
        }
    } catch {}
}
Update-ConfigPaths -Directory $initDir

# ==========================================
# 2B. WINDOW & PANEL SIZE PERSISTENCE ENGINE
# ==========================================
function Get-DefaultUiLayoutState {
    return [ordered]@{
        MainWindow = [ordered]@{
            Width               = 1260.0
            Height              = 860.0
            Left                = $null
            Top                 = $null
            WindowState         = "Normal"
            PackageLibraryWidth = 290.0
            UpperWorkspaceStar  = 2.6
            StatusLogStar       = 1.0
            TargetComputersStar = 1.0
            PackageStepsStar    = 1.0
        }
        ChildWindows = [ordered]@{
            DeploymentDetails = [ordered]@{
                Width          = 940.0
                Height         = 660.0
                StepsPaneStar  = 1.15
                OutputPaneStar = 1.0
            }
            AdBrowser = [ordered]@{
                Width               = 980.0
                Height              = 640.0
                OuTreeWidth         = 310.0
                LastImportedDomain  = ""
                LastImportedOuDN    = ""
                LastImportedSubOUs  = $true
            }
            CannedScripts = [ordered]@{
                Width         = 1060.0
                Height        = 690.0
                ListPaneWidth = 430.0
            }
            StepEditor = [ordered]@{
                Width  = 780.0
                Height = 680.0
            }
            Settings = [ordered]@{
                Width  = 580.0
                Height = 660.0
            }
        }
    }
}

$script:UiLayoutState = Get-DefaultUiLayoutState

function Load-UiLayoutState {
    $candidatePaths = @($script:UiLayoutFilePath, $script:BootstrapUiLayoutFilePath) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($path in $candidatePaths) {
        if (Test-Path $path) {
            try {
                $rawJson = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
                if ([string]::IsNullOrWhiteSpace($rawJson)) { continue }
                $loaded = ConvertFrom-Json -InputObject $rawJson -ErrorAction Stop
                if ($loaded -and $loaded.MainWindow) {
                    $mw = $loaded.MainWindow
                    if ($null -ne $mw.Width -and [double]$mw.Width -ge 900)  { $script:UiLayoutState.MainWindow.Width = [double]$mw.Width }
                    if ($null -ne $mw.Height -and [double]$mw.Height -ge 600) { $script:UiLayoutState.MainWindow.Height = [double]$mw.Height }
                    if ($null -ne $mw.Left) { $script:UiLayoutState.MainWindow.Left = [double]$mw.Left }
                    if ($null -ne $mw.Top)  { $script:UiLayoutState.MainWindow.Top  = [double]$mw.Top }
                    if ($mw.WindowState -in @("Normal", "Maximized")) { $script:UiLayoutState.MainWindow.WindowState = [string]$mw.WindowState }
                    if ($null -ne $mw.PackageLibraryWidth -and [double]$mw.PackageLibraryWidth -ge 160) {
                        $script:UiLayoutState.MainWindow.PackageLibraryWidth = [double]$mw.PackageLibraryWidth
                    }
                    if ($null -ne $mw.UpperWorkspaceStar -and [double]$mw.UpperWorkspaceStar -gt 0.1) {
                        $script:UiLayoutState.MainWindow.UpperWorkspaceStar = [double]$mw.UpperWorkspaceStar
                    }
                    if ($null -ne $mw.StatusLogStar -and [double]$mw.StatusLogStar -gt 0.1) {
                        $script:UiLayoutState.MainWindow.StatusLogStar = [double]$mw.StatusLogStar
                    }
                    if ($null -ne $mw.TargetComputersStar -and [double]$mw.TargetComputersStar -gt 0.1) {
                        $script:UiLayoutState.MainWindow.TargetComputersStar = [double]$mw.TargetComputersStar
                    }
                    if ($null -ne $mw.PackageStepsStar -and [double]$mw.PackageStepsStar -gt 0.1) {
                        $script:UiLayoutState.MainWindow.PackageStepsStar = [double]$mw.PackageStepsStar
                    }
                }
                if ($loaded -and $loaded.ChildWindows) {
                    foreach ($key in @("DeploymentDetails", "AdBrowser", "CannedScripts", "StepEditor", "Settings")) {
                        $cw = $loaded.ChildWindows.PSObject.Properties[$key]
                        if ($cw -and $cw.Value) {
                            $src = $cw.Value
                            $dst = $script:UiLayoutState.ChildWindows[$key]
                            if ($null -ne $src.Width -and [double]$src.Width -ge 360)   { $dst.Width = [double]$src.Width }
                            if ($null -ne $src.Height -and [double]$src.Height -ge 240) { $dst.Height = [double]$src.Height }
                            if ($null -ne $src.PSObject.Properties['StepsPaneStar'] -and $null -ne $src.StepsPaneStar -and [double]$src.StepsPaneStar -gt 0.1) {
                                $dst.StepsPaneStar = [double]$src.StepsPaneStar
                            }
                            if ($null -ne $src.PSObject.Properties['OutputPaneStar'] -and $null -ne $src.OutputPaneStar -and [double]$src.OutputPaneStar -gt 0.1) {
                                $dst.OutputPaneStar = [double]$src.OutputPaneStar
                            }
                            if ($null -ne $src.PSObject.Properties['OuTreeWidth'] -and $null -ne $src.OuTreeWidth -and [double]$src.OuTreeWidth -ge 180) {
                                $dst.OuTreeWidth = [double]$src.OuTreeWidth
                            }
                            if ($null -ne $src.PSObject.Properties['LastImportedDomain'] -and $null -ne $src.LastImportedDomain) {
                                $dst.LastImportedDomain = [string]$src.LastImportedDomain
                            }
                            if ($null -ne $src.PSObject.Properties['LastImportedOuDN'] -and $null -ne $src.LastImportedOuDN) {
                                $dst.LastImportedOuDN = [string]$src.LastImportedOuDN
                            }
                            if ($null -ne $src.PSObject.Properties['LastImportedSubOUs'] -and $null -ne $src.LastImportedSubOUs) {
                                $dst.LastImportedSubOUs = [bool]$src.LastImportedSubOUs
                            }
                            if ($null -ne $src.PSObject.Properties['ListPaneWidth'] -and $null -ne $src.ListPaneWidth -and [double]$src.ListPaneWidth -ge 260) {
                                $dst.ListPaneWidth = [double]$src.ListPaneWidth
                            }
                        }
                    }
                }
                break
            } catch {}
        }
    }
}

function Apply-MainWindowLayoutState {
    if (-not $window -or -not $script:UiLayoutState -or -not $script:UiLayoutState.MainWindow) { return }
    $mw = $script:UiLayoutState.MainWindow
    try {
        if ($mw.Width -ge $window.MinWidth)   { $window.Width  = [double]$mw.Width }
        if ($mw.Height -ge $window.MinHeight) { $window.Height = [double]$mw.Height }

        if ($null -ne $mw.Left -and $null -ne $mw.Top) {
            $vLeft   = [System.Windows.SystemParameters]::VirtualScreenLeft
            $vTop    = [System.Windows.SystemParameters]::VirtualScreenTop
            $vWidth  = [System.Windows.SystemParameters]::VirtualScreenWidth
            $vHeight = [System.Windows.SystemParameters]::VirtualScreenHeight
            if ($mw.Left -ge ($vLeft - 40) -and $mw.Top -ge ($vTop - 40) -and ($mw.Left + 200) -le ($vLeft + $vWidth) -and ($mw.Top + 150) -le ($vTop + $vHeight)) {
                $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
                $window.Left = [double]$mw.Left
                $window.Top  = [double]$mw.Top
            }
        }

        if ($mw.WindowState -eq "Maximized") {
            $window.WindowState = [System.Windows.WindowState]::Maximized
        }

        if ($colPackageLibrary -and $mw.PackageLibraryWidth -ge 180) {
            $colPackageLibrary.Width = New-Object System.Windows.GridLength([double]$mw.PackageLibraryWidth, [System.Windows.GridUnitType]::Pixel)
        }
        if ($rowUpperWorkspace -and $rowStatusLog -and $mw.UpperWorkspaceStar -gt 0.1 -and $mw.StatusLogStar -gt 0.1) {
            $rowUpperWorkspace.Height = New-Object System.Windows.GridLength([double]$mw.UpperWorkspaceStar, [System.Windows.GridUnitType]::Star)
            $rowStatusLog.Height      = New-Object System.Windows.GridLength([double]$mw.StatusLogStar, [System.Windows.GridUnitType]::Star)
        }
        if ($rowTargetComputers -and $rowPackageSteps -and $mw.TargetComputersStar -gt 0.1 -and $mw.PackageStepsStar -gt 0.1) {
            $rowTargetComputers.Height = New-Object System.Windows.GridLength([double]$mw.TargetComputersStar, [System.Windows.GridUnitType]::Star)
            $rowPackageSteps.Height    = New-Object System.Windows.GridLength([double]$mw.PackageStepsStar, [System.Windows.GridUnitType]::Star)
        }
    } catch {}
}

function Capture-MainWindowLayoutState {
    if (-not $window -or -not $script:UiLayoutState -or -not $script:UiLayoutState.MainWindow) { return }
    $mw = $script:UiLayoutState.MainWindow
    try {
        if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $mw.WindowState = "Maximized"
            $rb = $window.RestoreBounds
            if ($rb -and -not $rb.IsEmpty -and $rb.Width -ge 900 -and $rb.Height -ge 600) {
                $mw.Width  = [Math]::Round([double]$rb.Width, 1)
                $mw.Height = [Math]::Round([double]$rb.Height, 1)
                $mw.Left   = [Math]::Round([double]$rb.Left, 1)
                $mw.Top    = [Math]::Round([double]$rb.Top, 1)
            }
        } elseif ($window.WindowState -eq [System.Windows.WindowState]::Normal) {
            $mw.WindowState = "Normal"
            if ($window.ActualWidth -ge 900)  { $mw.Width  = [Math]::Round([double]$window.ActualWidth, 1) }
            elseif ($window.Width -ge 900)    { $mw.Width  = [Math]::Round([double]$window.Width, 1) }
            if ($window.ActualHeight -ge 600) { $mw.Height = [Math]::Round([double]$window.ActualHeight, 1) }
            elseif ($window.Height -ge 600)   { $mw.Height = [Math]::Round([double]$window.Height, 1) }
            if (-not [double]::IsNaN($window.Left) -and -not [double]::IsInfinity($window.Left)) {
                $mw.Left = [Math]::Round([double]$window.Left, 1)
            }
            if (-not [double]::IsNaN($window.Top) -and -not [double]::IsInfinity($window.Top)) {
                $mw.Top = [Math]::Round([double]$window.Top, 1)
            }
        }

        if ($colPackageLibrary) {
            $libW = if ($colPackageLibrary.ActualWidth -ge 180) { $colPackageLibrary.ActualWidth } elseif ($colPackageLibrary.Width.Value -ge 180) { $colPackageLibrary.Width.Value } else { 290.0 }
            $mw.PackageLibraryWidth = [Math]::Round([double]$libW, 1)
        }

        if ($rowUpperWorkspace -and $rowStatusLog) {
            if ($rowUpperWorkspace.ActualHeight -gt 50 -and $rowStatusLog.ActualHeight -gt 50) {
                $mw.UpperWorkspaceStar = [Math]::Round([double]$rowUpperWorkspace.ActualHeight, 1)
                $mw.StatusLogStar      = [Math]::Round([double]$rowStatusLog.ActualHeight, 1)
            } elseif ($rowUpperWorkspace.Height.IsStar -and $rowStatusLog.Height.IsStar) {
                $mw.UpperWorkspaceStar = [Math]::Round([double]$rowUpperWorkspace.Height.Value, 3)
                $mw.StatusLogStar      = [Math]::Round([double]$rowStatusLog.Height.Value, 3)
            }
        }

        if ($rowTargetComputers -and $rowPackageSteps) {
            if ($rowTargetComputers.ActualHeight -gt 50 -and $rowPackageSteps.ActualHeight -gt 50) {
                $mw.TargetComputersStar = [Math]::Round([double]$rowTargetComputers.ActualHeight, 1)
                $mw.PackageStepsStar    = [Math]::Round([double]$rowPackageSteps.ActualHeight, 1)
            } elseif ($rowTargetComputers.Height.IsStar -and $rowPackageSteps.Height.IsStar) {
                $mw.TargetComputersStar = [Math]::Round([double]$rowTargetComputers.Height.Value, 3)
                $mw.PackageStepsStar    = [Math]::Round([double]$rowPackageSteps.Height.Value, 3)
            }
        }
    } catch {}
}

function Save-UiLayoutState {
    try {
        Capture-MainWindowLayoutState
        $json = $script:UiLayoutState | ConvertTo-Json -Depth 6
        foreach ($path in @($script:UiLayoutFilePath, $script:BootstrapUiLayoutFilePath)) {
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                $parent = Split-Path -Path $path -Parent
                if ($parent -and -not (Test-Path $parent)) {
                    [void][System.IO.Directory]::CreateDirectory($parent)
                }
                [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8)
            }
        }
    } catch {}
}

function Register-ChildWindowLayoutPersistence {
    param(
        [System.Windows.Window]$Dialog,
        [string]$WindowKey,
        [System.Windows.Controls.RowDefinition]$TopRow = $null,
        [System.Windows.Controls.RowDefinition]$BottomRow = $null,
        [System.Windows.Controls.ColumnDefinition]$LeftColumn = $null,
        [string]$LeftColumnProp = "OuTreeWidth",
        [switch]$SkipHeightRestore
    )
    if (-not $Dialog -or [string]::IsNullOrWhiteSpace($WindowKey)) { return }
    if (-not $script:UiLayoutState -or -not $script:UiLayoutState.ChildWindows) { return }
    $cw = $script:UiLayoutState.ChildWindows[$WindowKey]
    if (-not $cw) { return }

    try {
        if ($cw.Width -and [double]$cw.Width -ge $Dialog.MinWidth) {
            $Dialog.Width = [double]$cw.Width
        }
        if (-not $SkipHeightRestore -and $cw.Height -and [double]$cw.Height -ge $Dialog.MinHeight) {
            $Dialog.Height = [double]$cw.Height
        }
        if ($TopRow -and $BottomRow -and $cw.StepsPaneStar -gt 0.1 -and $cw.OutputPaneStar -gt 0.1) {
            $TopRow.Height    = New-Object System.Windows.GridLength([double]$cw.StepsPaneStar, [System.Windows.GridUnitType]::Star)
            $BottomRow.Height = New-Object System.Windows.GridLength([double]$cw.OutputPaneStar, [System.Windows.GridUnitType]::Star)
        }
        if ($LeftColumn -and $cw[$LeftColumnProp] -and [double]$cw[$LeftColumnProp] -ge $LeftColumn.MinWidth) {
            $LeftColumn.Width = New-Object System.Windows.GridLength([double]$cw[$LeftColumnProp], [System.Windows.GridUnitType]::Pixel)
        }
    } catch {}

    $Dialog.Add_Closing(({
        try {
            if ($Dialog.ActualWidth -ge 360) {
                $cw.Width = [Math]::Round([double]$Dialog.ActualWidth, 1)
            } elseif ($Dialog.Width -ge 360) {
                $cw.Width = [Math]::Round([double]$Dialog.Width, 1)
            }
            if (-not $SkipHeightRestore) {
                if ($Dialog.ActualHeight -ge 240) {
                    $cw.Height = [Math]::Round([double]$Dialog.ActualHeight, 1)
                } elseif ($Dialog.Height -ge 240) {
                    $cw.Height = [Math]::Round([double]$Dialog.Height, 1)
                }
            }
            if ($TopRow -and $BottomRow -and $TopRow.ActualHeight -gt 40 -and $BottomRow.ActualHeight -gt 40) {
                $cw.StepsPaneStar  = [Math]::Round([double]$TopRow.ActualHeight, 1)
                $cw.OutputPaneStar = [Math]::Round([double]$BottomRow.ActualHeight, 1)
            }
            if ($LeftColumn -and $LeftColumn.ActualWidth -ge $LeftColumn.MinWidth) {
                $cw[$LeftColumnProp] = [Math]::Round([double]$LeftColumn.ActualWidth, 1)
            }
            Save-UiLayoutState
        } catch {}
    }).GetNewClosure())
}

foreach ($splitter in @($splitLibraryRight, $splitTargetsSteps, $splitUpperStatus)) {
    if ($splitter) {
        $splitter.Add_DragCompleted({ Save-UiLayoutState })
    }
}

$script:DiagLogFile = Join-Path $script:LogsDir 'psdeploy_diagnostic.log'

function Write-DiagnosticLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    try {
        if (-not (Test-Path $script:LogsDir)) {
            New-Item -ItemType Directory -Path $script:LogsDir -Force | Out-Null
        }
        $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
        $line = "[$ts] [$Level] $Message"
        Add-Content -Path $script:DiagLogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

function Invoke-WpfDoEvents {
    try {
        [System.Windows.Forms.Application]::DoEvents()
        if ($null -ne $window -and $null -ne $window.Dispatcher) {
            $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    } catch {}
}

Write-DiagnosticLog "PSDeploy initialized. ConfigDir=$($script:SettingsDir)" 

$script:AppSettings = [PSCustomObject]@{
    UseCurrentCred           = $true
    Domain                   = ""
    Username                 = ""
    EncryptedPass            = ""
    SecurePassword           = $null
    RemoteStagingDir         = "C:\Temp\PSDeploy"
    ConfigDirectory          = $script:SettingsDir
    MaxConcurrentTargets     = 8
    AutoProbeInventory       = $true
    AutoProbeIntervalMinutes = 15
}

function Update-SettingsSummaryLabel {
    $cfgPath = if ($script:SettingsDir) { $script:SettingsDir } else { "(default)" }
    $maxConc = if ($script:AppSettings.MaxConcurrentTargets) { [Math]::Min(8, [Math]::Max(1, [int]$script:AppSettings.MaxConcurrentTargets)) } else { 8 }
    $probeOn = if ($null -ne $script:AppSettings.AutoProbeInventory) { [bool]$script:AppSettings.AutoProbeInventory } else { $true }
    $probeMins = if ($script:AppSettings.AutoProbeIntervalMinutes) { [Math]::Max(1, [int]$script:AppSettings.AutoProbeIntervalMinutes) } else { 15 }
    $probeStr = if ($probeOn) { "Auto-Probe: On ($($probeMins)m)" } else { "Auto-Probe: Off" }
    if ($script:AppSettings.UseCurrentCred) {
        $curUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $lblSettingsSummary.Text = "Auth: Current Logon ($curUser) | Concurrency: $maxConc | $probeStr | Config: $cfgPath | Remote Staging: $($script:AppSettings.RemoteStagingDir)"
    } else {
        $usr = if (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Domain)) {
            "$($script:AppSettings.Domain)\$($script:AppSettings.Username)"
        } else {
            $script:AppSettings.Username
        }
        if ([string]::IsNullOrWhiteSpace($usr)) { $usr = "(not configured)" }
        $hasPass = ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0)
        $passStr = if ($hasPass) { "[Password Saved]" } else { "[No Password]" }
        $lblSettingsSummary.Text = "Auth: $usr $passStr | Concurrency: $maxConc | $probeStr | Config: $cfgPath | Remote Staging: $($script:AppSettings.RemoteStagingDir)"
    }
}

function Load-AppSettings {
    if (-not (Test-Path $script:SettingsFilePath)) {
        Update-SettingsSummaryLabel
        return
    }
    try {
        $json = [System.IO.File]::ReadAllText($script:SettingsFilePath, [System.Text.Encoding]::UTF8)
        $raw = ConvertFrom-Json -InputObject $json -ErrorAction Stop
        if ($null -ne $raw.UseCurrentCred) { $script:AppSettings.UseCurrentCred = [bool]$raw.UseCurrentCred }
        if ($raw.Domain) { $script:AppSettings.Domain = [string]$raw.Domain }
        if ($raw.Username) { $script:AppSettings.Username = [string]$raw.Username }
        if ($raw.RemoteStagingDir) { $script:AppSettings.RemoteStagingDir = [string]$raw.RemoteStagingDir }
        if ($null -ne $raw.MaxConcurrentTargets) {
            $parsedConc = 8
            if ([int]::TryParse("$($raw.MaxConcurrentTargets)", [ref]$parsedConc)) {
                $script:AppSettings.MaxConcurrentTargets = [Math]::Min(8, [Math]::Max(1, $parsedConc))
            }
        }
        if ($null -ne $raw.AutoProbeInventory) {
            $script:AppSettings.AutoProbeInventory = [bool]$raw.AutoProbeInventory
        }
        if ($null -ne $raw.AutoProbeIntervalMinutes) {
            $parsedProbeMins = 15
            if ([int]::TryParse("$($raw.AutoProbeIntervalMinutes)", [ref]$parsedProbeMins)) {
                $script:AppSettings.AutoProbeIntervalMinutes = [Math]::Min(240, [Math]::Max(1, $parsedProbeMins))
            }
        }
        if ($raw.ConfigDirectory -and $raw.ConfigDirectory -ne $script:SettingsDir) {
            Update-ConfigPaths -Directory [string]$raw.ConfigDirectory
        }
        if (-not [string]::IsNullOrWhiteSpace($raw.EncryptedPass)) {
            $script:AppSettings.EncryptedPass = [string]$raw.EncryptedPass
            try {
                Add-Type -AssemblyName System.Security -ErrorAction SilentlyContinue
                $encBytes = [System.Convert]::FromBase64String($raw.EncryptedPass)
                $plainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
                $plainStr = [System.Text.Encoding]::UTF8.GetString($plainBytes)
                $sec = New-Object System.Security.SecureString
                foreach ($c in $plainStr.ToCharArray()) { $sec.AppendChar($c) }
                $sec.MakeReadOnly()
                $script:AppSettings.SecurePassword = $sec
            } catch {
                $script:AppSettings.SecurePassword = $null
            }
        }
    } catch {}
    Update-SettingsSummaryLabel
}

function Save-AppSettings {
    try {
        $encB64 = ""
        if ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0) {
            Add-Type -AssemblyName System.Security -ErrorAction SilentlyContinue
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:AppSettings.SecurePassword)
            $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($plain)
            $encBytes = [System.Security.Cryptography.ProtectedData]::Protect($plainBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
            $encB64 = [System.Convert]::ToBase64String($encBytes)
        }
        $dto = [PSCustomObject]@{
            UseCurrentCred           = [bool]$script:AppSettings.UseCurrentCred
            Domain                   = [string]$script:AppSettings.Domain
            Username                 = [string]$script:AppSettings.Username
            EncryptedPass            = $encB64
            RemoteStagingDir         = [string]$script:AppSettings.RemoteStagingDir
            ConfigDirectory          = [string]$script:SettingsDir
            MaxConcurrentTargets     = [Math]::Min(8, [Math]::Max(1, [int]$script:AppSettings.MaxConcurrentTargets))
            AutoProbeInventory       = [bool]$script:AppSettings.AutoProbeInventory
            AutoProbeIntervalMinutes = [Math]::Min(240, [Math]::Max(1, [int]$script:AppSettings.AutoProbeIntervalMinutes))
        }
        $json = ConvertTo-Json -InputObject $dto -Depth 3
        [System.IO.File]::WriteAllText($script:SettingsFilePath, $json, [System.Text.Encoding]::UTF8)
    } catch {
        [System.Windows.MessageBox]::Show("Failed to save settings: $($_.Exception.Message)", "Settings Error", "OK", "Error")
    }
    Update-SettingsSummaryLabel
}

[xml]$settingsDialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PSDeploy Settings" Height="765" Width="610"
        WindowStartupLocation="CenterOwner" Background="#1E1E2E" Foreground="#CDD6F4"
        FontFamily="Segoe UI" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#F5E0DC"/><Setter Property="BorderBrush" Value="#45475A"/><Setter Property="Padding" Value="5,3"/><Setter Property="Height" Value="28"/><Setter Property="VerticalContentAlignment" Value="Center"/></Style>
        <Style TargetType="PasswordBox"><Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#F5E0DC"/><Setter Property="BorderBrush" Value="#45475A"/><Setter Property="Padding" Value="5,3"/><Setter Property="Height" Value="28"/><Setter Property="VerticalContentAlignment" Value="Center"/></Style>
        <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="8,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#181825" CornerRadius="6" Padding="12" Margin="0,0,0,12">
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="⚙️" FontSize="22" Margin="0,0,10,0" VerticalAlignment="Center"/>
                <StackPanel>
                    <TextBlock Text="APPLICATION &amp; WINRM SETTINGS" FontWeight="Bold" FontSize="13" Foreground="#89B4FA"/>
                    <TextBlock Text="Configure credentials, configuration directory, and staging folders used for deployments." Foreground="#A6ADC8" FontSize="11"/>
                </StackPanel>
            </StackPanel>
        </Border>

        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="0,0,4,0">
                <!-- Section 1: CREDENTIALS -->
                <Border Background="#181825" CornerRadius="6" Padding="12" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="🔑 WINRM DEPLOYMENT CREDENTIALS" FontWeight="Bold" Foreground="#A6E3A1" FontSize="12" Margin="0,0,0,8"/>
                        <CheckBox x:Name="chkDlgUseCurrent" Content="Use my current Windows logon credentials (Kerberos / NTLM default)" IsChecked="True" FontWeight="SemiBold" Margin="0,0,0,10"/>

                        <StackPanel x:Name="pnlDlgCredFields">
                            <Grid Margin="0,0,0,6">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="110"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <TextBlock Text="Domain:"/>
                                <TextBox x:Name="txtDlgDomain" Grid.Column="1" ToolTip="Domain name (e.g. CONTOSO) or machine name. Leave empty for local accounts."/>
                            </Grid>
                            <Grid Margin="0,0,0,6">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="110"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <TextBlock Text="Username:"/>
                                <TextBox x:Name="txtDlgUsername" Grid.Column="1" ToolTip="Account name with remote administration privileges on target machines."/>
                            </Grid>
                            <Grid Margin="0,0,0,6">
                                <Grid.ColumnDefinitions><ColumnDefinition Width="110"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                <TextBlock Text="Password:"/>
                                <PasswordBox x:Name="txtDlgPassword" Grid.Column="1" ToolTip="Password is encrypted using Windows DPAPI and stored only for your user account."/>
                            </Grid>
                            <TextBlock x:Name="lblSavedPassNote" Text="ℹ️ An encrypted password is currently saved. Enter a new password above to change it."
                                       Foreground="#F9E2AF" FontSize="10.5" Margin="110,0,0,4" Visibility="Collapsed"/>
                            <Button x:Name="btnClearCreds" Content="Clear Saved Password" Width="Auto" Padding="12,2" HorizontalAlignment="Left"
                                    Background="#45475A" Foreground="#F38BA8" Margin="110,2,0,0" ToolTip="Clear saved encrypted credentials from memory"/>
                        </StackPanel>
                    </StackPanel>
                </Border>

                <!-- Section 2: CONFIGURATION DIRECTORY -->
                <Border Background="#181825" CornerRadius="6" Padding="12" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="💾 APPLICATION CONFIGURATION &amp; LIBRARY DIRECTORY (Local / Shared)" FontWeight="Bold" Foreground="#89B4FA" FontSize="12" Margin="0,0,0,4"/>
                        <TextBlock Text="Directory where PSDeploy saves all application settings, deployment status logs, and the package library / deployment packages:" TextWrapping="Wrap" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,8"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtDlgConfigDir" Grid.Column="0" Margin="0,0,8,0" ToolTip="Directory where settings.json, package_library.json, and deployment logs are saved"/>
                            <Button x:Name="btnBrowseConfigDir" Grid.Column="1" Content="📂 Browse..." Width="Auto" Padding="12,2" Background="#45475A" Foreground="#CDD6F4" ToolTip="Browse for configuration and package library directory"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Section 3: STAGING DIRECTORY -->
                <Border Background="#181825" CornerRadius="6" Padding="12" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="&#x1F4C1; REMOTE MACHINE STAGING DIRECTORY" FontWeight="Bold" Foreground="#F9E2AF" FontSize="12" Margin="0,0,0,4"/>
                        <TextBlock Text="Temporary folder created on target machines to stage scripts, installers, and logs:" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,8"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtDlgRemoteDir" Grid.Column="0" Margin="0,0,8,0" Text="C:\Temp\PSDeploy" ToolTip="Remote target machine staging folder"/>
                            <Button x:Name="btnBrowseRemoteDir" Grid.Column="1" Content="Browse..." Width="Auto" Padding="12,2" Background="#45475A" Foreground="#CDD6F4" ToolTip="Select reference directory for staging path"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Section 4: CONCURRENT DEPLOYMENT -->
                <Border Background="#181825" CornerRadius="6" Padding="12" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="&#x26A1; CONCURRENT DEPLOYMENT (PARALLEL EXECUTION)" FontWeight="Bold" Foreground="#CBA6F7" FontSize="12" Margin="0,0,0,4"/>
                        <TextBlock Text="Maximum number of target computers to deploy to simultaneously (1 to 8 concurrent hosts):" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,8"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="150"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Text="Max Concurrent Deployments:" Margin="0,0,10,0"/>
                            <ComboBox x:Name="cmbDlgMaxConcurrency" Grid.Column="1" Height="28" Background="#313244" Foreground="#11111B" BorderBrush="#45475A" VerticalContentAlignment="Center" Padding="6,2" ToolTip="Select how many target computers can run deployment steps simultaneously (1 to 8)">
                                <ComboBoxItem Content="1 (Sequential)" Tag="1"/>
                                <ComboBoxItem Content="2 Hosts" Tag="2"/>
                                <ComboBoxItem Content="3 Hosts" Tag="3"/>
                                <ComboBoxItem Content="4 Hosts" Tag="4"/>
                                <ComboBoxItem Content="5 Hosts" Tag="5"/>
                                <ComboBoxItem Content="6 Hosts" Tag="6"/>
                                <ComboBoxItem Content="7 Hosts" Tag="7"/>
                                <ComboBoxItem Content="8 Hosts (Max)" Tag="8" IsSelected="True"/>
                            </ComboBox>
                            <TextBlock Grid.Column="2" Text="(Up to 8 simultaneous WinRM deployment sessions)" Foreground="#A6ADC8" FontSize="10.5" Margin="10,0,0,0" VerticalAlignment="Center"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Section 5: COMPUTER INVENTORY AUTO-PROBING -->
                <Border Background="#181825" CornerRadius="6" Padding="12">
                    <StackPanel>
                        <TextBlock Text="&#x1F50D; COMPUTER INVENTORY AUTO-PROBING" FontWeight="Bold" Foreground="#94E2D5" FontSize="12" Margin="0,0,0,4"/>
                        <CheckBox x:Name="chkDlgAutoProbe" Content="Automatically probe Computer Inventory status (Online/Offline, IP, Logon User)" IsChecked="True" FontWeight="SemiBold" Margin="0,2,0,8" ToolTip="When enabled, PSDeploy automatically probes inventory computers on startup and periodically in the background"/>
                        <Grid x:Name="pnlDlgAutoProbeInterval">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="170"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Text="Auto-Probe Interval:" Margin="0,0,10,0"/>
                            <ComboBox x:Name="cmbDlgAutoProbeInterval" Grid.Column="1" Height="28" Background="#313244" Foreground="#11111B" BorderBrush="#45475A" VerticalContentAlignment="Center" Padding="6,2" ToolTip="How often to automatically refresh Online/Offline status and Current Logon User in the background">
                                <ComboBoxItem Content="Every 5 Minutes" Tag="5"/>
                                <ComboBoxItem Content="Every 10 Minutes" Tag="10"/>
                                <ComboBoxItem Content="Every 15 Minutes (Default)" Tag="15" IsSelected="True"/>
                                <ComboBoxItem Content="Every 30 Minutes" Tag="30"/>
                                <ComboBoxItem Content="Every 60 Minutes (1 Hour)" Tag="60"/>
                            </ComboBox>
                            <TextBlock Grid.Column="2" Text="(Background non-blocking refresh)" Foreground="#A6ADC8" FontSize="10.5" Margin="10,0,0,0" VerticalAlignment="Center"/>
                        </Grid>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <!-- Dialog Buttons -->
        <Grid Grid.Row="2" Margin="0,15,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="btnSaveSettings" Grid.Column="1" Content="Save Settings" Width="Auto" MinWidth="110" Padding="14,2" Margin="0,0,8,0" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" ToolTip="Save all configuration settings"/>
            <Button x:Name="btnCancelSettings" Grid.Column="2" Content="Cancel" Width="Auto" MinWidth="90" Padding="12,2" Background="#45475A" Foreground="#CDD6F4" ToolTip="Discard changes"/>
        </Grid>
    </Grid>
</Window>
"@

function Show-SettingsDialog {
    $rdr = New-Object System.Xml.XmlNodeReader $settingsDialogXaml
    $dlg = [System.Windows.Markup.XamlReader]::Load($rdr)
    $dlg.Owner = $window

    $chkDlgUseCurrent   = $dlg.FindName("chkDlgUseCurrent")
    $pnlDlgCredFields   = $dlg.FindName("pnlDlgCredFields")
    $txtDlgDomain       = $dlg.FindName("txtDlgDomain")
    $txtDlgUsername     = $dlg.FindName("txtDlgUsername")
    $txtDlgPassword     = $dlg.FindName("txtDlgPassword")
    $lblSavedPassNote   = $dlg.FindName("lblSavedPassNote")
    $btnClearCreds      = $dlg.FindName("btnClearCreds")
    $txtDlgConfigDir    = $dlg.FindName("txtDlgConfigDir")
    $btnBrowseConfigDir = $dlg.FindName("btnBrowseConfigDir")
    $txtDlgRemoteDir      = $dlg.FindName("txtDlgRemoteDir")
    $btnBrowseRemoteDir   = $dlg.FindName("btnBrowseRemoteDir")
    $cmbDlgMaxConcurrency = $dlg.FindName("cmbDlgMaxConcurrency")
    $chkDlgAutoProbe         = $dlg.FindName("chkDlgAutoProbe")
    $pnlDlgAutoProbeInterval = $dlg.FindName("pnlDlgAutoProbeInterval")
    $cmbDlgAutoProbeInterval = $dlg.FindName("cmbDlgAutoProbeInterval")
    $btnSaveSettings      = $dlg.FindName("btnSaveSettings")
    $btnCancelSettings    = $dlg.FindName("btnCancelSettings")

    $chkDlgUseCurrent.IsChecked = [bool]$script:AppSettings.UseCurrentCred
    $txtDlgDomain.Text = [string]$script:AppSettings.Domain
    $txtDlgUsername.Text = [string]$script:AppSettings.Username
    $txtDlgConfigDir.Text = if (-not [string]::IsNullOrWhiteSpace($script:SettingsDir)) { $script:SettingsDir } else { $script:BootstrapDir }
    $txtDlgRemoteDir.Text = if (-not [string]::IsNullOrWhiteSpace($script:AppSettings.RemoteStagingDir)) { $script:AppSettings.RemoteStagingDir } else { "C:\Temp\PSDeploy" }
    $curConc = if ($script:AppSettings.MaxConcurrentTargets) { [Math]::Min(8, [Math]::Max(1, [int]$script:AppSettings.MaxConcurrentTargets)) } else { 8 }
    if ($cmbDlgMaxConcurrency) {
        $cmbDlgMaxConcurrency.SelectedIndex = ($curConc - 1)
    }
    if ($chkDlgAutoProbe) {
        $chkDlgAutoProbe.IsChecked = if ($null -ne $script:AppSettings.AutoProbeInventory) { [bool]$script:AppSettings.AutoProbeInventory } else { $true }
    }
    $curProbeMins = if ($script:AppSettings.AutoProbeIntervalMinutes) { [int]$script:AppSettings.AutoProbeIntervalMinutes } else { 15 }
    if ($cmbDlgAutoProbeInterval) {
        $matchedIdx = 2
        for ($i = 0; $i -lt $cmbDlgAutoProbeInterval.Items.Count; $i++) {
            $itemTag = "$($cmbDlgAutoProbeInterval.Items[$i].Tag)"
            if ($itemTag -eq "$curProbeMins") {
                $matchedIdx = $i
                break
            }
        }
        $cmbDlgAutoProbeInterval.SelectedIndex = $matchedIdx
    }
    $syncAutoProbeUI = {
        $probeOn = if ($chkDlgAutoProbe) { [bool]$chkDlgAutoProbe.IsChecked } else { $true }
        if ($pnlDlgAutoProbeInterval) {
            $pnlDlgAutoProbeInterval.IsEnabled = $probeOn
            $pnlDlgAutoProbeInterval.Opacity   = if ($probeOn) { 1.0 } else { 0.45 }
        }
    }
    if ($chkDlgAutoProbe) {
        $chkDlgAutoProbe.Add_Checked($syncAutoProbeUI)
        $chkDlgAutoProbe.Add_Unchecked($syncAutoProbeUI)
        & $syncAutoProbeUI
    }

    $btnBrowseConfigDir.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select PSDeploy Configuration & Library Directory"
        if (Test-Path $txtDlgConfigDir.Text) {
            $fbd.SelectedPath = $txtDlgConfigDir.Text
        }
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtDlgConfigDir.Text = $fbd.SelectedPath
        }
    })

    $hasExistingPass = ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0)
    if ($hasExistingPass) {
        $lblSavedPassNote.Visibility = [System.Windows.Visibility]::Visible
    }

    $syncCredUI = {
        $useCur = [bool]$chkDlgUseCurrent.IsChecked
        $pnlDlgCredFields.IsEnabled = -not $useCur
        $pnlDlgCredFields.Opacity   = if ($useCur) { 0.4 } else { 1.0 }
        $btnClearCreds.IsEnabled    = -not $useCur
    }
    $chkDlgUseCurrent.Add_Checked($syncCredUI)
    $chkDlgUseCurrent.Add_Unchecked($syncCredUI)
    & $syncCredUI

    $btnClearCreds.Add_Click({
        $script:AppSettings.SecurePassword = $null
        $script:AppSettings.EncryptedPass = ""
        $txtDlgPassword.Password = ""
        $lblSavedPassNote.Visibility = [System.Windows.Visibility]::Collapsed
        [System.Windows.MessageBox]::Show("Saved password cleared from memory. Click 'Save Settings' to commit.", "Credentials", "OK", "Information")
    })

    $btnBrowseRemoteDir.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select Staging Directory (can be used as reference path)"
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtDlgRemoteDir.Text = $fbd.SelectedPath
        }
    })

    $btnSaveSettings.Add_Click({
        $useCurrent = [bool]$chkDlgUseCurrent.IsChecked
        $remoteDir = $txtDlgRemoteDir.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($remoteDir)) {
            [System.Windows.MessageBox]::Show("Please enter a valid remote machine staging directory (e.g. C:\Temp\PSDeploy).", "Validation Error", "OK", "Warning")
            return
        }

        if (-not $useCurrent) {
            if ([string]::IsNullOrWhiteSpace($txtDlgUsername.Text)) {
                [System.Windows.MessageBox]::Show("Please enter a username or check 'Use my current Windows logon'.", "Validation Error", "OK", "Warning")
                return
            }
            if ($txtDlgPassword.SecurePassword.Length -eq 0 -and ($null -eq $script:AppSettings.SecurePassword -or $script:AppSettings.SecurePassword.Length -eq 0)) {
                [System.Windows.MessageBox]::Show("Please enter a password for user '$($txtDlgUsername.Text)'.", "Validation Error", "OK", "Warning")
                return
            }
        }

        $newConfigDir = $txtDlgConfigDir.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($newConfigDir)) {
            $newConfigDir = $script:BootstrapDir
        }

        if ($newConfigDir -ne $script:SettingsDir) {
            $oldPackagesDir = $script:PackagesDir
            $oldLogsDir = $script:LogsDir
            $oldSettingsDir = $script:SettingsDir

            Update-ConfigPaths -Directory $newConfigDir

            # Migrate package JSON files from old to new directory
            try {
                if ($oldPackagesDir -and (Test-Path $oldPackagesDir)) {
                    $oldPkgFiles = Get-ChildItem -LiteralPath $oldPackagesDir -Filter "*.json" -File -ErrorAction SilentlyContinue
                    foreach ($pf in $oldPkgFiles) {
                        $targetPath = [System.IO.Path]::Combine($script:PackagesDir, $pf.Name)
                        if (-not (Test-Path $targetPath)) {
                            Copy-Item -Path $pf.FullName -Destination $targetPath -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            } catch {}

            # Migrate log files from old to new directory
            try {
                if ($oldLogsDir -and (Test-Path $oldLogsDir)) {
                    $oldLogFiles = Get-ChildItem -LiteralPath $oldLogsDir -File -ErrorAction SilentlyContinue
                    foreach ($lf in $oldLogFiles) {
                        $targetPath = [System.IO.Path]::Combine($script:LogsDir, $lf.Name)
                        if (-not (Test-Path $targetPath)) {
                            Copy-Item -Path $lf.FullName -Destination $targetPath -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            } catch {}

            # Migrate package_library.json if not present in new directory
            try {
                if ($oldSettingsDir -and (-not (Test-Path $script:LibraryPath))) {
                    $oldLib = Join-Path $oldSettingsDir "package_library.json"
                    if (Test-Path $oldLib) {
                        Copy-Item -Path $oldLib -Destination $script:LibraryPath -Force -ErrorAction SilentlyContinue
                    }
                }
            } catch {}

            try {
                if (-not (Test-Path $script:BootstrapDir)) {
                    [void][System.IO.Directory]::CreateDirectory($script:BootstrapDir)
                }
                $bootDto = @{ ConfigDirectory = $newConfigDir }
                $bootJson = ConvertTo-Json -InputObject $bootDto
                [System.IO.File]::WriteAllText($script:BootstrapFilePath, $bootJson, [System.Text.Encoding]::UTF8)
            } catch {}

            if (Test-Path $script:LibraryPath) {
                Load-PackageLibrary
                Refresh-LibraryTreeView
            } else {
                Save-PackageLibrary
            }

            if (Test-Path $script:StatusStateFilePath) {
                Load-PersistentStatusState
            } else {
                Save-PersistentStatusState
            }
        } else {
            try {
                if (-not (Test-Path $script:BootstrapDir)) {
                    [void][System.IO.Directory]::CreateDirectory($script:BootstrapDir)
                }
                $bootDto = @{ ConfigDirectory = $script:SettingsDir }
                $bootJson = ConvertTo-Json -InputObject $bootDto
                [System.IO.File]::WriteAllText($script:BootstrapFilePath, $bootJson, [System.Text.Encoding]::UTF8)
            } catch {}
        }

        $script:AppSettings.UseCurrentCred = $useCurrent
        $script:AppSettings.Domain = $txtDlgDomain.Text.Trim()
        $script:AppSettings.Username = $txtDlgUsername.Text.Trim()
        $script:AppSettings.RemoteStagingDir = $remoteDir
        $script:AppSettings.ConfigDirectory = $script:SettingsDir
        if ($cmbDlgMaxConcurrency -and $cmbDlgMaxConcurrency.SelectedIndex -ge 0) {
            $script:AppSettings.MaxConcurrentTargets = [Math]::Min(8, [Math]::Max(1, ($cmbDlgMaxConcurrency.SelectedIndex + 1)))
        }
        $wasAutoProbe = [bool]$script:AppSettings.AutoProbeInventory
        if ($chkDlgAutoProbe) {
            $script:AppSettings.AutoProbeInventory = [bool]$chkDlgAutoProbe.IsChecked
        }
        if ($cmbDlgAutoProbeInterval -and $cmbDlgAutoProbeInterval.SelectedItem -and $cmbDlgAutoProbeInterval.SelectedItem.Tag) {
            $parsedMins = 15
            if ([int]::TryParse("$($cmbDlgAutoProbeInterval.SelectedItem.Tag)", [ref]$parsedMins)) {
                $script:AppSettings.AutoProbeIntervalMinutes = [Math]::Min(240, [Math]::Max(1, $parsedMins))
            }
        }

        if ($txtDlgPassword.SecurePassword.Length -gt 0) {
            $script:AppSettings.SecurePassword = $txtDlgPassword.SecurePassword.Copy()
        }

        Save-AppSettings
        if (Get-Command Update-AutoProbeTimer -ErrorAction SilentlyContinue) {
            Update-AutoProbeTimer
        }
        if ((-not $wasAutoProbe) -and [bool]$script:AppSettings.AutoProbeInventory -and $script:TargetsCollection.Count -gt 0 -and $script:ActiveProbeJobs.Count -eq 0) {
            Start-BackgroundTargetProbe -TargetsToProbe @($script:TargetsCollection)
        }
        $dlg.DialogResult = $true
        $dlg.Close()
    })

    $btnCancelSettings.Add_Click({
        $dlg.DialogResult = $false
        $dlg.Close()
    })

    Register-ChildWindowLayoutPersistence -Dialog $dlg -WindowKey "Settings"
    [void]$dlg.ShowDialog()
}

$btnSettings.Add_Click({ Show-SettingsDialog })
Load-AppSettings

# ==========================================
# 3. STEP MODEL & STEP EDITOR DIALOG
# ==========================================
function Update-StepSummary {
    param($Step)
    if ($Step.Type -eq 'Pause') {
        $Step.Summary = "Pause for $($Step.PauseSeconds) second(s)"
    } elseif ($Step.Type -eq 'Installer') {
        $file = if ($Step.PayloadPath) { [System.IO.Path]::GetFileName($Step.PayloadPath) } else { "(no payload)" }
        $flags = if ($Step.Parameters) { " [Args: $($Step.Parameters)]" } else { "" }
        $inc = if ($Step.IncludeFolder) { " +Folder" } else { "" }
        $Step.Summary = "Payload: $file$inc$flags"
    } else {
        $first = ($Step.Script -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
        $summaryText = if ($first) { $first.Trim() } else { "(empty script)" }
        if (-not [string]::IsNullOrWhiteSpace($Step.Parameters)) {
            $summaryText = "[Args: $($Step.Parameters)] $summaryText"
        }
        $Step.Summary = $summaryText
    }
}

function New-StepObject {
    param(
        [string]$Name,
        [string]$Type = "PowerShell",
        [string]$Script = "",
        [string]$Parameters = "",
        [string]$PayloadPath = "",
        [bool]$IncludeFolder = $false,
        [bool]$SilentInstall = $true,
        [int]$PauseSeconds = 0
    )
    $s = [PSCustomObject]@{
        Order         = 0
        Name          = $Name
        Type          = $Type
        Script        = $Script
        Parameters    = $Parameters
        PayloadPath   = $PayloadPath
        IncludeFolder = $IncludeFolder
        SilentInstall = $SilentInstall
        PauseSeconds  = $PauseSeconds
        Summary       = ""
    }
    Update-StepSummary $s
    return $s
}

function Update-ActivePackageBanner {
    if ($lblDeployActivePkg) {
        $pName = if ($txtPkgName -and -not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) { $txtPkgName.Text.Trim() } else { "(Untitled Package)" }
        $fName = if (Get-Command Get-SelectedLibraryFolder -ErrorAction SilentlyContinue) { Get-SelectedLibraryFolder } else { "General" }
        $stepCnt = if ($script:StepsCollection) { $script:StepsCollection.Count } else { 0 }
        $lblDeployActivePkg.Text = "$pName  [$fName • $stepCnt step(s)]"
    }
}

function Show-PackageStepsModal {
    if (-not $script:PkgStepsModalWindow) { return }
    if (-not $script:PkgStepsModalWindow.Owner -and $window.IsLoaded) {
        try { $script:PkgStepsModalWindow.Owner = $window } catch {}
    }
    $pName = if ($txtPkgName -and -not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) { $txtPkgName.Text.Trim() } else { "Custom Deployment Package" }
    $script:PkgStepsModalWindow.Title = "Package Steps Builder — $pName"
    [void]$script:PkgStepsModalWindow.ShowDialog()
    Update-ActivePackageBanner
}

function Renumber-Steps {
    for ($i = 0; $i -lt $script:StepsCollection.Count; $i++) {
        $script:StepsCollection[$i].Order = $i + 1
    }
    if ($dgSteps) { $dgSteps.Items.Refresh() }
    if ($dgDeployPreviewSteps) { $dgDeployPreviewSteps.Items.Refresh() }
    Update-ActivePackageBanner
}

[xml]$editorXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Edit Step" Height="680" Width="720"
        WindowStartupLocation="CenterOwner" Background="#1E1E2E" Foreground="#CDD6F4"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#F5E0DC"/><Setter Property="BorderBrush" Value="#45475A"/><Setter Property="Padding" Value="5,3"/><Setter Property="Height" Value="28"/><Setter Property="VerticalContentAlignment" Value="Center"/></Style>
        <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
        <ControlTemplate x:Key="ComboBoxToggleButtonTemplate" TargetType="ToggleButton">
            <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="20"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="1" Text="▼" Foreground="#CDD6F4" FontSize="10" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Grid>
            </Border>
        </ControlTemplate>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Template="{StaticResource ComboBoxToggleButtonTemplate}"
                                          Background="#313244" BorderBrush="#45475A" BorderThickness="1"
                                          Focusable="False" ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"/>
                            <ContentPresenter x:Name="ContentSite" IsHitTestVisible="False"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="8,3,24,3"
                                              VerticalAlignment="Center" HorizontalAlignment="Left"
                                              TextElement.Foreground="#CDD6F4" TextElement.FontWeight="SemiBold"/>
                            <Popup x:Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                                <Grid x:Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="200">
                                    <Border Background="#181825" BorderBrush="#45475A" BorderThickness="1" CornerRadius="3">
                                        <ScrollViewer SnapsToDevicePixels="True">
                                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="6,4"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#A6E3A1"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#313244"/>
                    <Setter Property="Foreground" Value="#89B4FA"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="8,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- ROW 0: Step Name -->
        <Grid Grid.Row="0" Margin="0,0,0,8">
            <Grid.ColumnDefinitions><ColumnDefinition Width="90"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Text="Step Name:"/>
            <TextBox x:Name="edtName" Grid.Column="1"/>
        </Grid>

        <!-- ROW 1: Step Type & Pause Seconds -->
        <Grid Grid.Row="1" Margin="0,0,0,8">
            <Grid.ColumnDefinitions><ColumnDefinition Width="90"/><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Text="Step Type:"/>
            <ComboBox x:Name="edtType" Grid.Column="1">
                <ComboBoxItem Content="PowerShell"/>
                <ComboBoxItem Content="Batch"/>
                <ComboBoxItem Content="Installer"/>
                <ComboBoxItem Content="Pause"/>
            </ComboBox>
            <StackPanel x:Name="pnlPause" Grid.Column="2" Orientation="Horizontal" Margin="15,0,0,0">
                <TextBlock Text="Pause Seconds:" Margin="0,0,6,0"/>
                <TextBox x:Name="edtPauseSeconds" Text="60" Width="70"/>
            </StackPanel>
        </Grid>

        <!-- ROW 2: Installer Payload Path & Options -->
        <Grid x:Name="pnlInstaller" Grid.Row="2" Margin="0,0,0,8">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="0,0,0,6">
                <Grid.ColumnDefinitions><ColumnDefinition Width="90"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="Payload File:"/>
                <TextBox x:Name="edtPayloadPath" Grid.Column="1" Margin="0,0,6,0" ToolTip="Select installer or payload (.msi, .exe, .msu, .msp, .bat, .cmd, .ps1)"/>
                <Button x:Name="edtBrowsePayload" Grid.Column="2" Content="Browse..." Width="Auto" MinWidth="80" Padding="10,2" Background="#45475A" Foreground="#CDD6F4" ToolTip="Browse for software installer or payload file"/>
            </Grid>
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="90,0,0,0">
                <CheckBox x:Name="edtIncludeFolder" Content="Include entire parent folder" Margin="0,0,20,0" ToolTip="Copies all files in the installer folder to the remote target"/>
                <CheckBox x:Name="edtSilentInstall" Content="Run Silently by default" IsChecked="True" ToolTip="Appends silent installation switches"/>
            </StackPanel>
        </Grid>

        <!-- ROW 3: Parameters -->
        <Grid x:Name="pnlParameters" Grid.Row="3" Margin="0,0,0,8">
            <Grid.ColumnDefinitions><ColumnDefinition Width="90"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Text="Parameters:"/>
            <TextBox x:Name="edtParameters" Grid.Column="1" ToolTip="Optional arguments or silent flags passed to the script or installer"/>
        </Grid>

        <!-- ROW 4: Script Label -->
        <TextBlock x:Name="lblScript" Grid.Row="4" Text="Script Content:" Foreground="#A6ADC8" Margin="0,0,0,5"/>

        <!-- ROW 5: Script TextBox -->
        <TextBox x:Name="edtScript" Grid.Row="5" Background="#313244" Foreground="#F5E0DC" BorderBrush="#45475A"
                 FontFamily="Consolas" FontSize="12" AcceptsReturn="True" AcceptsTab="True"
                 Height="Auto" MinHeight="220" VerticalAlignment="Stretch" VerticalContentAlignment="Top" Padding="8,6"
                 VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>

        <!-- ROW 6: Dialog Buttons -->
        <Grid Grid.Row="6" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="edtInsertFile" Grid.Column="0" Content="📂 Insert Script File..." Width="Auto" MinWidth="140" Padding="12,2" Background="#45475A" Foreground="#CDD6F4" ToolTip="Read script content from file into editor"/>
            <Button x:Name="edtOK" Grid.Column="2" Content="OK" Width="Auto" MinWidth="90" Padding="12,2" Margin="0,0,8,0" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" ToolTip="Save step changes"/>
            <Button x:Name="edtCancel" Grid.Column="3" Content="Cancel" Width="Auto" MinWidth="90" Padding="12,2" Background="#45475A" Foreground="#CDD6F4" ToolTip="Discard step changes"/>
        </Grid>
    </Grid>
</Window>
"@

function Show-StepEditor {
    param($Existing, [string]$DefaultType = "PowerShell")
    $rdr = New-Object System.Xml.XmlNodeReader $editorXaml
    $dlg = [System.Windows.Markup.XamlReader]::Load($rdr)
    $dlg.Owner = $window

    $edtName          = $dlg.FindName("edtName")
    $edtType          = $dlg.FindName("edtType")
    $pnlPause         = $dlg.FindName("pnlPause")
    $edtPause         = $dlg.FindName("edtPauseSeconds")
    $pnlInstaller     = $dlg.FindName("pnlInstaller")
    $edtPayloadPath   = $dlg.FindName("edtPayloadPath")
    $edtBrowsePayload = $dlg.FindName("edtBrowsePayload")
    $edtIncludeFolder = $dlg.FindName("edtIncludeFolder")
    $edtSilentInstall = $dlg.FindName("edtSilentInstall")
    $pnlParameters    = $dlg.FindName("pnlParameters")
    $edtParameters    = $dlg.FindName("edtParameters")
    $lblScript        = $dlg.FindName("lblScript")
    $edtScript        = $dlg.FindName("edtScript")
    $edtInsert        = $dlg.FindName("edtInsertFile")
    $edtOK            = $dlg.FindName("edtOK")
    $edtCancel        = $dlg.FindName("edtCancel")

    if ($Existing) {
        $dlg.Title = "Edit Step — $($Existing.Name)"
        $edtName.Text = $Existing.Name
        $typeIdx = switch ($Existing.Type) {
            "PowerShell" { 0 }
            "Batch"      { 1 }
            "Installer"  { 2 }
            "Pause"      { 3 }
            default      { 0 }
        }
        $edtType.SelectedIndex = $typeIdx
        $edtPause.Text = "$($Existing.PauseSeconds)"
        $edtPayloadPath.Text = "$($Existing.PayloadPath)"
        $edtIncludeFolder.IsChecked = [bool]$Existing.IncludeFolder
        $edtSilentInstall.IsChecked = [bool]$Existing.SilentInstall
        $edtParameters.Text = "$($Existing.Parameters)"
        $edtScript.Text = "$($Existing.Script)"
    } else {
        $typeIdx = switch ($DefaultType) {
            "PowerShell" { 0 }
            "Batch"      { 1 }
            "Installer"  { 2 }
            "Pause"      { 3 }
            default      { 0 }
        }
        $edtType.SelectedIndex = $typeIdx
        $edtPause.Text = "60"
        $edtParameters.Text = ""
        $edtIncludeFolder.IsChecked = $false
        $edtSilentInstall.IsChecked = $true
    }

    $syncType = {
        $selType = $edtType.SelectedIndex # 0: PowerShell, 1: Batch, 2: Installer, 3: Pause
        if ($selType -eq 3) { # Pause
            $pnlPause.Visibility      = [System.Windows.Visibility]::Visible
            $pnlInstaller.Visibility  = [System.Windows.Visibility]::Collapsed
            $pnlParameters.Visibility = [System.Windows.Visibility]::Collapsed
            $lblScript.Visibility     = [System.Windows.Visibility]::Collapsed
            $edtScript.Visibility     = [System.Windows.Visibility]::Collapsed
            $edtInsert.Visibility     = [System.Windows.Visibility]::Collapsed
            $dlg.Height = 220
        } elseif ($selType -eq 2) { # Installer
            $pnlPause.Visibility      = [System.Windows.Visibility]::Collapsed
            $pnlInstaller.Visibility  = [System.Windows.Visibility]::Visible
            $pnlParameters.Visibility = [System.Windows.Visibility]::Visible
            $lblScript.Visibility     = [System.Windows.Visibility]::Collapsed
            $edtScript.Visibility     = [System.Windows.Visibility]::Collapsed
            $edtInsert.Visibility     = [System.Windows.Visibility]::Collapsed
            $dlg.Height = 310
        } else { # PowerShell (0) or Batch (1)
            $pnlPause.Visibility      = [System.Windows.Visibility]::Collapsed
            $pnlInstaller.Visibility  = [System.Windows.Visibility]::Collapsed
            $pnlParameters.Visibility = [System.Windows.Visibility]::Visible
            $lblScript.Visibility     = [System.Windows.Visibility]::Visible
            $edtScript.Visibility     = [System.Windows.Visibility]::Visible
            $edtInsert.Visibility     = [System.Windows.Visibility]::Visible
            $lblScript.Text = if ($selType -eq 1) { "Command / Batch Script Content:" } else { "PowerShell Script (executed in isolated process on target):" }
            $dlg.Height = 680
        }
    }
    $edtType.Add_SelectionChanged($syncType)
    & $syncType

    $edtBrowsePayload.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Software Payloads (*.msi;*.exe;*.msu;*.msp;*.bat;*.cmd;*.ps1)|*.msi;*.exe;*.msu;*.msp;*.bat;*.cmd;*.ps1|All Files (*.*)|*.*"
        $ofd.Title = "Select Installer / Software Payload"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $edtPayloadPath.Text = $ofd.FileName
            if ([string]::IsNullOrWhiteSpace($edtName.Text)) {
                $edtName.Text = "Install $([System.IO.Path]::GetFileNameWithoutExtension($ofd.FileName))"
            }
            # Auto-populate recommended silent install parameters
            $ext = [System.IO.Path]::GetExtension($ofd.FileName).ToLower()
            if ([string]::IsNullOrWhiteSpace($edtParameters.Text) -or $edtParameters.Text -match '^(/qn|/quiet|/S|-ExecutionPolicy)') {
                switch ($ext) {
                    ".msi" { $edtParameters.Text = "/qn /norestart" }
                    ".msp" { $edtParameters.Text = "/qn /norestart" }
                    ".msu" { $edtParameters.Text = "/quiet /norestart" }
                    ".exe" { $edtParameters.Text = "/S /norestart" }
                    ".bat" { $edtParameters.Text = "/c" }
                    ".cmd" { $edtParameters.Text = "/c" }
                    ".ps1" { $edtParameters.Text = "-ExecutionPolicy Bypass -NoProfile" }
                }
            }
        }
    })

    $edtInsert.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Script Files (*.ps1;*.bat;*.cmd)|*.ps1;*.bat;*.cmd|All Files (*.*)|*.*"
        $ofd.Title = "Select Script File to Insert"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $edtScript.Text = Get-Content -Path $ofd.FileName -Raw
            if ([string]::IsNullOrWhiteSpace($edtName.Text)) {
                $edtName.Text = [System.IO.Path]::GetFileNameWithoutExtension($ofd.FileName)
            }
            $ext = [System.IO.Path]::GetExtension($ofd.FileName).ToLower()
            if ($ext -eq '.bat' -or $ext -eq '.cmd') {
                $edtType.SelectedIndex = 1 # Batch
            } else {
                $edtType.SelectedIndex = 0 # PowerShell
            }
        }
    })

    $script:editorResult = $null
    $edtOK.Add_Click({
        if ([string]::IsNullOrWhiteSpace($edtName.Text)) {
            [System.Windows.MessageBox]::Show("Step name is required.", "Validation", "OK", "Warning")
            return
        }

        $selType = $edtType.SelectedIndex
        $typeName = switch ($selType) {
            0 { "PowerShell" }
            1 { "Batch" }
            2 { "Installer" }
            3 { "Pause" }
            default { "PowerShell" }
        }

        $pSec = 0
        if ($typeName -eq 'Pause') {
            if (-not [int]::TryParse($edtPause.Text, [ref]$pSec) -or $pSec -le 0) {
                [System.Windows.MessageBox]::Show("Pause seconds must be a positive integer.", "Validation", "OK", "Warning")
                return
            }
        }

        if ($typeName -eq 'Installer') {
            if ([string]::IsNullOrWhiteSpace($edtPayloadPath.Text)) {
                [System.Windows.MessageBox]::Show("Payload file path is required for Software Installer steps.", "Validation", "OK", "Warning")
                return
            }
        }

        $stepScriptVal        = if ($typeName -eq 'Pause' -or $typeName -eq 'Installer') { "" } else { $edtScript.Text }
        $stepParamsVal        = if ($typeName -eq 'Pause') { "" } else { $edtParameters.Text.Trim() }
        $stepPayloadPathVal   = if ($typeName -eq 'Installer') { $edtPayloadPath.Text.Trim() } else { "" }
        $stepIncludeFolderVal = if ($typeName -eq 'Installer') { [bool]$edtIncludeFolder.IsChecked } else { $false }
        $stepSilentInstallVal = if ($typeName -eq 'Installer') { [bool]$edtSilentInstall.IsChecked } else { $false }

        if ($Existing) {
            $Existing.Name          = $edtName.Text.Trim()
            $Existing.Type          = $typeName
            $Existing.Script        = $stepScriptVal
            $Existing.Parameters    = $stepParamsVal
            $Existing.PayloadPath   = $stepPayloadPathVal
            $Existing.IncludeFolder = $stepIncludeFolderVal
            $Existing.SilentInstall = $stepSilentInstallVal
            $Existing.PauseSeconds  = $pSec
            Update-StepSummary $Existing
            $script:editorResult = $Existing
        } else {
            $s = New-StepObject -Name $edtName.Text.Trim() `
                                -Type $typeName `
                                -Script $stepScriptVal `
                                -Parameters $stepParamsVal `
                                -PayloadPath $stepPayloadPathVal `
                                -IncludeFolder $stepIncludeFolderVal `
                                -SilentInstall $stepSilentInstallVal `
                                -PauseSeconds $pSec
            $script:editorResult = $s
        }

        $dlg.DialogResult = $true
        $dlg.Close()
    })

    $edtCancel.Add_Click({
        $dlg.DialogResult = $false
        $dlg.Close()
    })

    $isScriptMode = ($edtType.SelectedIndex -le 1)
    if ($isScriptMode) {
        Register-ChildWindowLayoutPersistence -Dialog $dlg -WindowKey "StepEditor"
    } else {
        Register-ChildWindowLayoutPersistence -Dialog $dlg -WindowKey "StepEditor" -SkipHeightRestore
    }

    if ($dlg.ShowDialog() -eq $true) {
        return $script:editorResult
    }
    return $null
}

function Edit-SelectedStep {
    $sel = $dgSteps.SelectedItem
    if (-not $sel) { return }
    $res = Show-StepEditor -Existing $sel
    if ($res) {
        $dgSteps.Items.Refresh()
    }
}

function Remove-SelectedStep {
    $sel = $dgSteps.SelectedItem
    if (-not $sel) { return }
    [void]$script:StepsCollection.Remove($sel)
    Renumber-Steps
}

function Clear-AllSteps {
    if ($script:StepsCollection.Count -eq 0) { return }
    $ans = [System.Windows.MessageBox]::Show("Clear all steps from current package?", "Confirm Clear", "YesNo", "Question")
    if ($ans -eq 'Yes') {
        $script:StepsCollection.Clear()
        Renumber-Steps
    }
}

function Move-StepUp {
    $sel = $dgSteps.SelectedItem
    if (-not $sel) { return }
    $idx = $script:StepsCollection.IndexOf($sel)
    if ($idx -gt 0) {
        $script:StepsCollection.RemoveAt($idx)
        $script:StepsCollection.Insert($idx - 1, $sel)
        Renumber-Steps
        $dgSteps.SelectedIndex = $idx - 1
    }
}

function Move-StepDown {
    $sel = $dgSteps.SelectedItem
    if (-not $sel) { return }
    $idx = $script:StepsCollection.IndexOf($sel)
    if ($idx -ge 0 -and $idx -lt $script:StepsCollection.Count - 1) {
        $script:StepsCollection.RemoveAt($idx)
        $script:StepsCollection.Insert($idx + 1, $sel)
        Renumber-Steps
        $dgSteps.SelectedIndex = $idx + 1
    }
}

# Wire Step Creation & Editing Events
$btnAddScript.Add_Click({
    $s = Show-StepEditor -DefaultType "PowerShell"
    if ($s) {
        $script:StepsCollection.Add($s)
        Renumber-Steps
    }
})

$btnAddBatch.Add_Click({
    $s = Show-StepEditor -DefaultType "Batch"
    if ($s) {
        $script:StepsCollection.Add($s)
        Renumber-Steps
    }
})

$btnAddInstaller.Add_Click({
    $s = Show-StepEditor -DefaultType "Installer"
    if ($s) {
        $script:StepsCollection.Add($s)
        Renumber-Steps
    }
})

$btnAddPause.Add_Click({
    $s = Show-StepEditor -DefaultType "Pause"
    if ($s) {
        $script:StepsCollection.Add($s)
        Renumber-Steps
    }
})

$btnCannedScripts.Add_Click({ Show-CannedScriptsDialog })

# ==========================================
# 3B. CANNED SCRIPTS CATALOG & DIALOG (SYSADMIN / IT TROUBLESHOOTING & LOOKUP)
# ==========================================
function Get-CannedScriptsCatalog {
    return @(
        # --- CATEGORY 1: System & OS Lookup ---
        [PSCustomObject]@{
            Category    = "System & OS Lookup"
            Name        = "System Hardware, OS, BIOS & Uptime Summary"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Queries CIM (Win32_OperatingSystem, Win32_ComputerSystem, Win32_BIOS, Win32_Processor) for hostname, domain, OS build, install date, last boot time, uptime, CPU, RAM, and serial number. [Prereqs: WinRM + WMI (Winmgmt) running, Local Admin; No external dependencies]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native PowerShell 5.1+ CIM cmdlets)
# - Services     : WinRM (WSMan), Windows Management Instrumentation (Winmgmt) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
`$os   = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
`$cs   = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
`$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
`$cpu  = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
`$uptime = (Get-Date) - `$os.LastBootUpTime

[PSCustomObject]@{
    ComputerName  = `$env:COMPUTERNAME
    DomainOrWorkg = `$cs.Domain
    Manufacturer  = `$cs.Manufacturer
    Model         = `$cs.Model
    SerialNumber  = if (`$bios) { `$bios.SerialNumber } else { 'N/A' }
    BIOSVersion   = if (`$bios) { (`$bios.SMBIOSBIOSVersion -join ', ') } else { 'N/A' }
    OSCaption     = `$os.Caption
    OSVersion     = `$os.Version
    OSBuild       = `$os.BuildNumber
    Architecture  = `$os.OSArchitecture
    CPU           = if (`$cpu) { `$cpu.Name } else { 'N/A' }
    TotalRAM_GB   = [math]::Round(`$cs.TotalPhysicalMemory / 1GB, 2)
    FreeRAM_GB    = [math]::Round(`$os.FreePhysicalMemory / 1MB, 2)
    LastBootTime  = `$os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
    Uptime        = "{0}d {1}h {2}m" -f `$uptime.Days, `$uptime.Hours, `$uptime.Minutes
} | Format-List
"@
        },
        [PSCustomObject]@{
            Category    = "System & OS Lookup"
            Name        = "Systeminfo Summary (OS, Boot Time, Domain, Hotfixes)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Runs native Windows systeminfo.exe and filters key identity, OS version, system boot time, domain, and network card lines for fast CMD lookup. [Prereqs: WinRM + Winmgmt running, Local Admin; No external dependencies]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native systeminfo.exe & findstr.exe)
REM - Services     : WinRM (WSMan), Windows Management Instrumentation (Winmgmt) must be Running
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
echo === SYSTEMINFO SUMMARY ON %COMPUTERNAME% ===
systeminfo /fo list | findstr /B /I /C:"Host Name" /C:"OS Name" /C:"OS Version" /C:"System Boot Time" /C:"System Manufacturer" /C:"System Model" /C:"System Type" /C:"Total Physical Memory" /C:"Domain" /C:"Logon Server"
if %ERRORLEVEL% NEQ 0 systeminfo
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "System & OS Lookup"
            Name        = "Pending Reboot Status Check (CBS, WU, PendingFileRename)"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Checks Component Based Servicing (CBS), Windows Update AutoUpdate, PendingFileRenameOperations, and SCCM CCMClientSDK to determine if a reboot is pending. [Prereqs: WinRM running, Local Admin read access to HKLM; No external dependencies]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native Registry provider)
# - Services     : WinRM (WSMan) must be Running
# - Permissions  : Local Administrator on target computer (read access to HKLM servicing keys)
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
`$cbsReboot = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
`$wuReboot  = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
`$smKey     = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
`$pfrReboot = [bool](`$null -ne `$smKey -and `$smKey.PendingFileRenameOperations)

[PSCustomObject]@{
    ComputerName              = `$env:COMPUTERNAME
    AnyRebootPending          = (`$cbsReboot -or `$wuReboot -or `$pfrReboot)
    CBS_RebootPending         = `$cbsReboot
    WindowsUpdate_RebootReq   = `$wuReboot
    PendingFileRenamePresent  = `$pfrReboot
} | Format-List
"@
        },
        [PSCustomObject]@{
            Category    = "System & OS Lookup"
            Name        = "Installed Windows Hotfixes & KB History (Latest 25)"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Lists the 25 most recently installed Windows Updates / KBs sorted by InstalledOn date descending. [Prereqs: WinRM + WMI (Winmgmt) + TrustedInstaller available, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native Get-HotFix / Win32_QuickFixEngineering)
# - Services     : WinRM (WSMan), WMI (Winmgmt), Windows Modules Installer (TrustedInstaller)
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
Get-HotFix |
    Sort-Object { if (`$_.InstalledOn) { [datetime]`$_.InstalledOn } else { [datetime]::MinValue } } -Descending |
    Select-Object -First 25 HotFixID, Description, InstalledBy, InstalledOn |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "System & OS Lookup"
            Name        = "Last 15 Reboot, Shutdown & Unexpected Kernel-Power Events"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Queries the System Event Log for Event IDs 1074 (User/Process initiated reboot), 6005/6006 (EventLog start/stop), 6008 (Unexpected shutdown), and 41 (Kernel-Power). [Prereqs: WinRM + Windows Event Log (EventLog) service running, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native Get-WinEvent cmdlet)
# - Services     : WinRM (WSMan), Windows Event Log (EventLog) must be Running
# - Permissions  : Local Administrator or Event Log Readers group on target computer
# - GPO / Network: System Event Log must not be disabled by GPO
`$events = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = @(41, 1074, 6005, 6006, 6008) } -MaxEvents 15 -ErrorAction SilentlyContinue)
if (`$events.Count -eq 0) {
    Write-Output "No matching reboot/shutdown events found in System Event Log on `$env:COMPUTERNAME."
} else {
    `$events |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, @{N='Details';E={(`$_.Message -split "`r?`n")[0]}} |
        Format-Table -AutoSize -Wrap
}
"@
        },
        [PSCustomObject]@{
            Category    = "System & OS Lookup"
            Name        = "System Environment Variables & PATH Lookup"
            Type        = "Batch"
            Parameters  = ""
            Description = "Outputs all system/process environment variables, OS version/architecture, and timezone via native CMD without deprecated WMIC dependency. [Prereqs: WinRM running, Local Admin; Win11 24H2+ safe]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Uses native set, reg.exe, and tzutil.exe; WMIC-free for Windows 11 24H2+ / Server 2025 compatibility)
REM - Services     : WinRM (WSMan) must be Running
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
echo === ENVIRONMENT VARIABLES ON %COMPUTERNAME% ===
set
echo.
echo === OS VERSION ^& ARCHITECTURE (REGISTRY) ===
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2>nul
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2>nul
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2>nul
echo.
echo === SYSTEM TIMEZONE ===
tzutil /g
exit /b 0
"@
        },

        # --- CATEGORY 2: AD, Users & Group Policy ---
        [PSCustomObject]@{
            Category    = "AD, Users & Group Policy"
            Name        = "Logged-On Users & RDP/Console Sessions (quser)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Lists all currently logged-on interactive and RDP users, session IDs, states, idle times, and logon timestamps using quser / qwinsta. [Prereqs: WinRM + TermService running, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native quser.exe / qwinsta.exe; handles 'No User exists for *' cleanly with exit code 0)
REM - Services     : WinRM (WSMan), Remote Desktop Services (TermService) for session enumeration
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
echo === LOGGED-ON USERS (QUSER) ON %COMPUTERNAME% ===
quser 2>nul || qwinsta 2>nul || echo No active interactive/RDP user sessions found.
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "AD, Users & Group Policy"
            Name        = "Force Group Policy Update (gpupdate /force)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Non-interactively forces a background Computer and User Group Policy refresh without prompting for logoff/boot (pipes 'N' if prompted). [Prereqs: Domain-joined target, AD DC network reachability, gpsvc service, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : Active Directory domain membership & line-of-sight to a Domain Controller (LDAP 389 / SMB 445 / Kerberos 88)
REM - Services     : WinRM (WSMan), Group Policy Client (gpsvc), Netlogon must be Running
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Target machine must be able to reach SYSVOL and AD Domain Controllers
echo Forcing Group Policy update on %COMPUTERNAME%...
echo N | gpupdate /force /wait:60
exit /b %ERRORLEVEL%
"@
        },
        [PSCustomObject]@{
            Category    = "AD, Users & Group Policy"
            Name        = "Group Policy Resultant Set of Policy Report (gpresult)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Displays applied Computer Group Policy Objects (GPOs), security groups, and last policy application time. [Prereqs: WinRM + gpsvc + Winmgmt running, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native gpresult.exe querying Computer RSoP scope; does not require interactive user profile)
REM - Services     : WinRM (WSMan), Group Policy Client (gpsvc), WMI (Winmgmt) must be Running
REM - Permissions  : Local Administrator on target computer (required for /scope:computer RSoP query)
REM - GPO / Network: Resultant Set of Policy (RSoP) logging must not be disabled by GPO ('Turn off Resultant Set of Policy logging')
echo === COMPUTER GROUP POLICY RESULT ON %COMPUTERNAME% ===
gpresult /r /scope:computer
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "AD, Users & Group Policy"
            Name        = "Domain Controller Discovery, Secure Channel & WhoAmI"
            Type        = "Batch"
            Parameters  = ""
            Description = "Runs whoami /all, discovers the authenticating Domain Controller via nltest /dsgetdc, and verifies AD secure channel status via nltest /sc_query. [Prereqs: Domain-joined target, Netlogon running, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : Native whoami.exe & nltest.exe (Active Directory domain-joined target required for nltest DC discovery)
REM - Services     : WinRM (WSMan), Netlogon service must be Running for secure channel query
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Network reachability to AD Domain Controller (UDP/TCP 389, 88, 445, 135)
echo === CURRENT EXECUTION CONTEXT (WHOAMI) ===
whoami /fqdn 2>nul || whoami
whoami /groups
echo.
echo === DOMAIN CONTROLLER DISCOVERY (NLTEST) ===
if defined USERDNSDOMAIN (
    nltest /dsgetdc:%USERDNSDOMAIN% 2>nul
    nltest /sc_query:%USERDNSDOMAIN% 2>nul
) else (
    echo Target %COMPUTERNAME% is in a Workgroup or USERDNSDOMAIN is not set.
)
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "AD, Users & Group Policy"
            Name        = "Local Administrators Group Membership Audit"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Enumerates all local and domain members inside the local Administrators group for security auditing and privilege verification. [Prereqs: WinRM + SAM (SamSs) running, Local Admin; falls back to net localgroup if unresolvable SIDs exist]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Microsoft.PowerShell.LocalAccounts module (automatically falls back to native 'net localgroup Administrators' if orphaned/unresolvable AD SIDs cause Get-LocalGroupMember to error)
# - Services     : WinRM (WSMan), Security Accounts Manager (SamSs) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Domain Controller connectivity recommended to resolve domain member SIDs to friendly names
Write-Output "=== LOCAL ADMINISTRATORS ON `$env:COMPUTERNAME ==="
try {
    Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop |
        Select-Object Name, ObjectClass, PrincipalSource, SID |
        Format-Table -AutoSize
} catch {
    net localgroup Administrators
}
"@
        },
        [PSCustomObject]@{
            Category    = "AD, Users & Group Policy"
            Name        = "User Profiles Inventory & Last Use Time"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Queries Win32_UserProfile for non-special user profiles on the machine, showing LocalPath, Loaded status, and LastUseTime. [Prereqs: WinRM + WMI (Winmgmt) + User Profile Service (ProfSvc) running, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native CIM Win32_UserProfile class)
# - Services     : WinRM (WSMan), WMI (Winmgmt), User Profile Service (ProfSvc) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop |
    Where-Object { -not `$_.Special } |
    Select-Object LocalPath, SID, Loaded, LastUseTime |
    Sort-Object LastUseTime -Descending |
    Format-Table -AutoSize
"@
        },

        # --- CATEGORY 3: Network & Connectivity ---
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "Full IP Configuration, MAC, DHCP & DNS Lookup (ipconfig /all)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Displays complete network adapter configuration including IPv4/IPv6 addresses, default gateways, DHCP servers, DNS servers, and MAC addresses. [Prereqs: WinRM running, Local Admin; No external dependencies]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native ipconfig.exe)
REM - Services     : WinRM (WSMan), Network Store Interface (nsi) must be Running
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
ipconfig /all
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "Flush DNS Resolver Cache & Re-Register Dynamic DNS"
            Type        = "Batch"
            Parameters  = ""
            Description = "Purges the local DNS resolver cache (ipconfig /flushdns) and initiates dynamic DNS registration (ipconfig /registerdns). [Prereqs: WinRM + DNS Client (Dnscache) + DHCP Client running, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native ipconfig.exe)
REM - Services     : WinRM (WSMan), DNS Client (Dnscache), and DHCP Client (Dhcp) must be Running
REM - Permissions  : Local Administrator on target computer (required for /registerdns)
REM - GPO / Network: Dynamic DNS updates must be permitted by DNS server / GPO ('DynamicUpdate')
ipconfig /flushdns
ipconfig /registerdns
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "Active Listening TCP/UDP Ports & Owning Process Lookup"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Maps all listening TCP ports on the remote endpoint to their owning Process ID (PID), Process Name, and executable path. [Prereqs: WinRM + WMI (Winmgmt) running, NetTCPIP module (Win8+/Server 2012+), Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Built-in NetTCPIP module (Windows 8+ / Windows Server 2012+)
# - Services     : WinRM (WSMan), WMI (Winmgmt), Network Store Interface (nsi) must be Running
# - Permissions  : Local Administrator on target computer (required to inspect elevated process names)
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
`$procs = @{}
Get-Process -ErrorAction SilentlyContinue | ForEach-Object { `$procs[`$_.Id] = `$_.ProcessName }

Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, State, OwningProcess, @{N='ProcessName';E={`$procs[[int]`$_.OwningProcess]}} |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "Netstat Active Connections, Routing Table & ARP Cache"
            Type        = "Batch"
            Parameters  = ""
            Description = "Runs netstat -ano (listening & established), route print (IPv4 routing table), and arp -a (neighbor MAC table). [Prereqs: WinRM running, Local Admin; No external dependencies]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native netstat.exe, route.exe, arp.exe)
REM - Services     : WinRM (WSMan), TCP/IP Protocol Driver (Tcpip) must be Running
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
echo === ACTIVE TCP/UDP CONNECTIONS (NETSTAT -ANO) ===
netstat -ano | findstr /I "LISTENING ESTABLISHED"
if %ERRORLEVEL% NEQ 0 netstat -ano
echo.
echo === IPV4 ROUTING TABLE ===
route print -4
echo.
echo === ARP CACHE ===
arp -a
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "Active Network Adapters, Link Speed & DNS Servers"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Displays physical/virtual Up network adapters with InterfaceDescription, MAC address, LinkSpeed, IPv4 address, Gateway, and DNS servers. [Prereqs: WinRM + WMI (Winmgmt) + NetAdapter/NetTCPIP modules, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Built-in NetTCPIP and NetAdapter modules (Windows 8+ / Server 2012+)
# - Services     : WinRM (WSMan), WMI (Winmgmt), Network Connections (NetMan) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
Get-NetIPConfiguration -ErrorAction SilentlyContinue |
    Where-Object { `$_.NetAdapter.Status -eq 'Up' } |
    Select-Object InterfaceAlias,
                  @{N='Description';E={`$_.NetAdapter.InterfaceDescription}},
                  @{N='LinkSpeed';E={`$_.NetAdapter.LinkSpeed}},
                  @{N='IPv4Address';E={(`$_.IPv4Address.IPAddress -join ', ')}},
                  @{N='Gateway';E={(`$_.IPv4DefaultGateway.NextHop -join ', ')}},
                  @{N='DNSServers';E={(`$_.DNSServer.ServerAddresses -join ', ')}} |
    Format-List
"@
        },
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "WinRM Service, Listeners & Windows Firewall Profile Status"
            Type        = "Batch"
            Parameters  = ""
            Description = "Checks WinRM service state, active WinRM HTTP/HTTPS listeners, and Domain/Private/Public Windows Firewall profile states. [Prereqs: WinRM + MpsSvc (Windows Defender Firewall) running, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native sc.exe, winrm.cmd, netsh.exe)
REM - Services     : WinRM (WSMan), Windows Defender Firewall (MpsSvc) must be Running
REM - Permissions  : Local Administrator on target computer (required to enumerate WinRM config and firewall profiles)
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
echo === WINRM SERVICE ^& LISTENERS ===
sc query WinRM
call winrm enumerate winrm/config/listener
echo.
echo === WINDOWS FIREWALL PROFILES ===
netsh advfirewall show allprofiles state
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Network & Connectivity"
            Name        = "Reset Winsock Catalog & TCP/IP Stack (Requires Reboot Later)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Flushes DNS, resets the Winsock catalog (netsh winsock reset), and resets the IPv4/IPv6 TCP/IP stack without forcing an immediate reboot. [Prereqs: WinRM running, Local Admin; Note: netsh int ip reset may return code 1 on virtual adapters]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native ipconfig.exe & netsh.exe)
REM - Services     : WinRM (WSMan), DNS Client (Dnscache), Network Store Interface (nsi) must be Running
REM - Permissions  : Local Administrator on target computer (mandatory for Winsock and TCP/IP stack registry resets)
REM - GPO / Network: Does NOT force an immediate reboot, so current WinRM session stays alive; schedule a maintenance reboot later
ipconfig /flushdns
netsh winsock reset
netsh int ip reset
echo Winsock and TCP/IP stack reset completed. Schedule a reboot to finalize changes.
exit /b 0
"@
        },

        # --- CATEGORY 4: Disk, Storage & BitLocker ---
        [PSCustomObject]@{
            Category    = "Disk, Storage & BitLocker"
            Name        = "Disk Free Space, Volume Health & Physical Disk SMART Status"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Lists all fixed volumes with DriveLetter, Label, FileSystem, Size (GB), Free Space (GB), Percent Free, HealthStatus, and physical media type (SSD/HDD/NVMe). [Prereqs: WinRM + WMI (Winmgmt) + Storage module, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Built-in Storage module (Get-Volume / Get-PhysicalDisk; Windows 8+ / Server 2012+)
# - Services     : WinRM (WSMan), WMI (Winmgmt), Virtual Disk (vds) / Microsoft Storage Spaces SMP (smphost)
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
Write-Output "=== LOGICAL VOLUMES ==="
Get-Volume -ErrorAction SilentlyContinue | Where-Object { `$_.DriveType -eq 'Fixed' -and `$_.DriveLetter } |
    Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus,
                  @{N='Size_GB';E={[math]::Round(`$_.Size / 1GB, 2)}},
                  @{N='Free_GB';E={[math]::Round(`$_.SizeRemaining / 1GB, 2)}},
                  @{N='Free_Pct';E={if (`$_.Size -gt 0) { [math]::Round((`$_.SizeRemaining / `$_.Size) * 100, 1) } else { 0 }}} |
    Format-Table -AutoSize

Write-Output "=== PHYSICAL DISKS ==="
Get-PhysicalDisk -ErrorAction SilentlyContinue |
    Select-Object DeviceId, FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus,
                  @{N='Size_GB';E={[math]::Round(`$_.Size / 1GB, 2)}} |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Disk, Storage & BitLocker"
            Name        = "BitLocker Encryption Status & Key Protectors Lookup (manage-bde)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Queries BitLocker Drive Encryption status, conversion state, encryption method, and key protectors across all volumes. [Prereqs: WinRM + BDESVC running, BitLocker feature installed on Server OS, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : manage-bde.exe (Built into Windows Pro/Enterprise; on Windows Server requires 'BitLocker Drive Encryption' feature installed)
REM - Services     : WinRM (WSMan), BitLocker Drive Encryption Service (BDESVC), WMI (Winmgmt)
REM - Permissions  : Local Administrator on target computer (mandatory for manage-bde)
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
where manage-bde >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo manage-bde.exe is not installed on %COMPUTERNAME% ^(BitLocker feature not present^).
    exit /b 0
)
echo === BITLOCKER STATUS ON %COMPUTERNAME% ===
manage-bde -status
echo.
echo === C: DRIVE KEY PROTECTORS ===
manage-bde -protectors -get C: 2>nul
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Disk, Storage & BitLocker"
            Name        = "Suspend / Disable BitLocker Key Protectors on C: Drive"
            Type        = "Batch"
            Parameters  = ""
            Description = "Suspends BitLocker protection on C: drive (manage-bde -protectors -disable C:) so BIOS/firmware updates or maintenance reboots do not trigger a BitLocker recovery prompt. [Prereqs: WinRM + BDESVC running, C: encrypted with BitLocker, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : manage-bde.exe (BitLocker Drive Encryption feature must be installed and C: must have active BitLocker protectors)
REM - Services     : WinRM (WSMan), BitLocker Drive Encryption Service (BDESVC) must be Running
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Note: Group Policy or Intune/MDM BitLocker policies may automatically re-enable protection on next policy refresh or reboot
where manage-bde >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo manage-bde.exe is not installed on %COMPUTERNAME%.
    exit /b 1
)
echo Suspending BitLocker protection on C: drive...
manage-bde -protectors -disable C:
manage-bde -status C:
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Disk, Storage & BitLocker"
            Name        = "Top 20 Largest Files on C: Drive (Over 100 MB)"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Scans C:\ (excluding Windows\WinSxS and ReparsePoints) for the 20 largest files over 100 MB to quickly diagnose full disk alerts. [Prereqs: WinRM running, Local Admin; Note: Full C:\ scan may take 30-120s depending on disk speed]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native FileSystem provider using -LiteralPath for wildcard-safe traversal)
# - Services     : WinRM (WSMan) must be Running
# - Permissions  : Local Administrator on target computer (required to scan protected system and user profile directories)
# - GPO / Network: Full C:\ traversal can take 30-120 seconds on large disks; ensure step timeout is >= 5 minutes
Get-ChildItem -LiteralPath 'C:\' -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { `$_.Length -ge 100MB -and -not (`$_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and `$_.FullName -notlike 'C:\Windows\WinSxS\*' } |
    Sort-Object Length -Descending |
    Select-Object -First 20 @{N='Size_MB';E={[math]::Round(`$_.Length / 1MB, 1)}}, LastWriteTime, FullName |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Disk, Storage & BitLocker"
            Name        = "Clean Windows Temp, User Temp & Old SoftwareDistribution Downloads"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Safely deletes unlocked temporary files in C:\Windows\Temp, C:\Users\*\AppData\Local\Temp, and C:\Windows\SoftwareDistribution\Download, reporting space reclaimed. [Prereqs: WinRM running, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native FileSystem provider; locked/in-use files are safely skipped via -ErrorAction SilentlyContinue)
# - Services     : WinRM (WSMan) must be Running
# - Permissions  : Local Administrator on target computer (required to delete files across all user profiles and C:\Windows\Temp)
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
`$before = (Get-PSDrive -Name C).Free
`$paths = @(
    'C:\Windows\Temp\*',
    'C:\Windows\SoftwareDistribution\Download\*',
    'C:\Users\*\AppData\Local\Temp\*'
)
foreach (`$p in `$paths) {
    Remove-Item -Path `$p -Recurse -Force -ErrorAction SilentlyContinue
}
`$after = (Get-PSDrive -Name C).Free
`$freedMB = [math]::Round((`$after - `$before) / 1MB, 2)
`$freeGB = [math]::Round(`$after / 1GB, 2)
Write-Output "Disk cleanup finished on `$env:COMPUTERNAME. Reclaimed: `$freedMB MB. Current Free Space: `$freeGB GB"
"@
        },
        [PSCustomObject]@{
            Category    = "Disk, Storage & BitLocker"
            Name        = "Check NTFS Dirty Bit & Read-Only Disk Integrity Scan"
            Type        = "Batch"
            Parameters  = ""
            Description = "Queries fsutil dirty query C: to check if volume C: is marked dirty and runs a non-destructive read-only chkdsk C: scan. [Prereqs: WinRM running, Local Admin; No external dependencies]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native fsutil.exe and chkdsk.exe in read-only mode)
REM - Services     : WinRM (WSMan) must be Running
REM - Permissions  : Local Administrator on target computer (mandatory for raw volume access in fsutil and chkdsk)
REM - GPO / Network: Runs read-only chkdsk without /F or /R so volume C: is not locked and no reboot prompt blocks remote execution
echo === NTFS DIRTY BIT STATUS ===
fsutil dirty query C:
echo.
echo === READ-ONLY CHKDSK SCAN ===
chkdsk C:
exit /b 0
"@
        },

        # --- CATEGORY 5: Services, Processes & Event Logs ---
        [PSCustomObject]@{
            Category    = "Services, Processes & Event Logs"
            Name        = "Top 15 CPU & Memory Consuming Processes"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Lists the top 15 processes by WorkingSet RAM and CPU seconds to diagnose high resource utilization on a remote endpoint. [Prereqs: WinRM running, Local Admin; No external dependencies]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native Get-Process cmdlet)
# - Services     : WinRM (WSMan) must be Running
# - Permissions  : Local Administrator on target computer (required to read CPU metrics across all user/system sessions)
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
Write-Output "=== TOP 15 PROCESSES BY MEMORY (RAM) ==="
Get-Process -ErrorAction SilentlyContinue |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 15 Id, ProcessName, @{N='CPU_Sec';E={[math]::Round(`$_.CPU, 1)}}, @{N='RAM_MB';E={[math]::Round(`$_.WorkingSet64 / 1MB, 1)}}, Responding |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Services, Processes & Event Logs"
            Name        = "Critical & Error System / Application Event Logs (Last 24 Hours)"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Retrieves the latest 25 Critical (Level 1) and Error (Level 2) events from both the System and Application logs over the past 24 hours. [Prereqs: WinRM + Windows Event Log (EventLog) running, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native Get-WinEvent cmdlet)
# - Services     : WinRM (WSMan), Windows Event Log (EventLog) must be Running
# - Permissions  : Local Administrator or Event Log Readers group on target computer
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
`$since = (Get-Date).AddHours(-24)
`$events = @(Get-WinEvent -FilterHashtable @{ LogName = @('System', 'Application'); Level = @(1, 2); StartTime = `$since } -MaxEvents 25 -ErrorAction SilentlyContinue)
if (`$events.Count -eq 0) {
    Write-Output "No Critical or Error events recorded in System/Application logs in the last 24 hours on `$env:COMPUTERNAME."
} else {
    `$events |
        Select-Object TimeCreated, LogName, Id, LevelDisplayName, ProviderName, @{N='Message';E={(`$_.Message -split "`r?`n")[0]}} |
        Format-Table -AutoSize -Wrap
}
"@
        },
        [PSCustomObject]@{
            Category    = "Services, Processes & Event Logs"
            Name        = "Stopped Automatic Services Lookup (Alert Check)"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Finds all Windows Services configured for Automatic startup that are currently Stopped, helping identify crashed agents or services. [Prereqs: WinRM + WMI (Winmgmt) running, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native CIM Win32_Service query)
# - Services     : WinRM (WSMan), Windows Management Instrumentation (Winmgmt) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Note: Services with Delayed Auto-Start or trigger-start (e.g., sppsvc, edgeupdate) may normally appear Stopped when idle
Get-CimInstance -ClassName Win32_Service -Filter "StartMode = 'Auto' AND State != 'Running'" -ErrorAction Stop |
    Select-Object Name, DisplayName, State, StartMode, ExitCode, StartName |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Services, Processes & Event Logs"
            Name        = "Restart Print Spooler & Purge Stuck Print Queue"
            Type        = "Batch"
            Parameters  = ""
            Description = "Stops the Print Spooler service, deletes corrupted/stuck .SHD and .SPL print jobs in System32\spool\PRINTERS, and restarts the Spooler. [Prereqs: WinRM running, Spooler service not Disabled by GPO, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native net.exe & del commands)
REM - Services     : WinRM (WSMan); Print Spooler (Spooler) service must not be Disabled by GPO (e.g., PrintNightmare hardening on servers)
REM - Permissions  : Local Administrator on target computer (required to stop/start Spooler and purge System32\spool\PRINTERS)
REM - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
echo Stopping Print Spooler service...
net stop spooler /y 2>nul
echo Clearing stuck print jobs...
del /Q /F /S "%SystemRoot%\System32\spool\PRINTERS\*.*" 2>nul
echo Starting Print Spooler service...
net start spooler
exit /b %ERRORLEVEL%
"@
        },
        [PSCustomObject]@{
            Category    = "Services, Processes & Event Logs"
            Name        = "Reset Windows Update Services (wuauserv, bits, cryptsvc)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Stops Windows Update, BITS, and Cryptographic services, clears stuck BITS downloader queue files, and restarts the services to fix stuck updates. [Prereqs: WinRM running, wuauserv/bits/cryptsvc not Disabled by GPO, Local Admin]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native net.exe & del commands)
REM - Services     : WinRM (WSMan); Windows Update (wuauserv), BITS, and Cryptographic Services (cryptsvc) must not be Disabled by GPO
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: If WSUS or Windows Update for Business GPOs are enforced, the client will re-sync against the configured update source
net stop wuauserv /y 2>nul
net stop bits /y 2>nul
net stop cryptsvc /y 2>nul
del /f /q "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat" 2>nul
net start cryptsvc 2>nul
net start bits 2>nul
net start wuauserv 2>nul
echo Windows Update services (cryptsvc, bits, wuauserv) reset completed on %COMPUTERNAME%.
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Services, Processes & Event Logs"
            Name        = "Verify & Salvage WMI Repository (winmgmt)"
            Type        = "Batch"
            Parameters  = ""
            Description = "Runs winmgmt /verifyrepository and winmgmt /salvagerepository to repair corrupted WMI namespaces on remote workstations. [Prereqs: WinRM running, Local Admin; No external dependencies]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native winmgmt.exe)
REM - Services     : WinRM (WSMan), Windows Management Instrumentation (Winmgmt)
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: Safe non-destructive WMI repository verification and salvage (does not drop WinRM session)
winmgmt /verifyrepository
winmgmt /salvagerepository
exit /b 0
"@
        },

        # --- CATEGORY 6: Security, Defender & OS Repair ---
        [PSCustomObject]@{
            Category    = "Security, Defender & OS Repair"
            Name        = "Windows Defender Antivirus Status & Signature Lookup"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Checks Microsoft Defender Antivirus real-time protection status, tamper protection, engine/signature versions, and recent threat detections. [Prereqs: WinRM + WinDefend + Winmgmt running, Defender feature present, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Built-in Defender PowerShell module (Get-MpComputerStatus / Get-MpThreatDetection)
# - Services     : WinRM (WSMan), Microsoft Defender Antivirus Service (WinDefend), WMI (Winmgmt) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Note: If a third-party EDR/AV is installed or GPO 'Turn off Microsoft Defender Antivirus' is enabled, Defender may be in passive/disabled mode
if (-not (Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
    Write-Output "Microsoft Defender PowerShell module is not available on `$env:COMPUTERNAME."
    exit 0
}
Get-MpComputerStatus -ErrorAction Stop |
    Select-Object AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled,
                  BehaviorMonitorEnabled, IoavProtectionEnabled, IsTamperProtected,
                  AntivirusSignatureVersion, AntivirusSignatureLastUpdated,
                  QuickScanEndTime, FullScanEndTime |
    Format-List

Write-Output "=== RECENT THREAT DETECTIONS ==="
Get-MpThreatDetection -ErrorAction SilentlyContinue | Select-Object -First 10 | Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Security, Defender & OS Repair"
            Name        = "Update Windows Defender Signatures & Run Quick Scan"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Updates Microsoft Defender Antivirus definitions (Update-MpSignature) and executes a non-interactive Quick Scan (Start-MpScan -ScanType QuickScan). [Prereqs: WinRM + WinDefend running, Internet/WSUS/UNC signature source reachable, Local Admin]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Built-in Defender PowerShell module (Update-MpSignature / Start-MpScan)
# - Services     : WinRM (WSMan), Microsoft Defender Antivirus Service (WinDefend), Windows Update (wuauserv) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Target requires network access to Microsoft Update, WSUS, or configured GPO signature share; Defender must not be disabled by GPO or 3rd-party AV
Write-Output "Updating Microsoft Defender virus definitions on `$env:COMPUTERNAME..."
Update-MpSignature -ErrorAction Stop
Write-Output "Running Microsoft Defender Quick Scan on `$env:COMPUTERNAME..."
Start-MpScan -ScanType QuickScan -ErrorAction Stop
Write-Output "Defender signature update and Quick Scan completed successfully."
"@
        },
        [PSCustomObject]@{
            Category    = "Security, Defender & OS Repair"
            Name        = "DISM Component Store CheckHealth & SFC System File Scan"
            Type        = "Batch"
            Parameters  = ""
            Description = "Runs DISM /Online /Cleanup-Image /CheckHealth followed by sfc /scannow to detect and repair corrupted Windows system files. [Prereqs: WinRM + TrustedInstaller running, Local Admin; Note: SFC scan takes 3-10 minutes]"
            Script      = @"
@echo off
REM [REMOTE PREREQUISITES & DEPENDENCIES]
REM - Dependencies : None (Native DISM.exe & sfc.exe)
REM - Services     : WinRM (WSMan), Windows Modules Installer (TrustedInstaller) must not be Disabled
REM - Permissions  : Local Administrator on target computer
REM - GPO / Network: sfc /scannow typically takes 3-10 minutes to complete; ensure package step timeout is >= 15 minutes
echo === DISM COMPONENT STORE HEALTH CHECK ===
DISM.exe /Online /Cleanup-Image /CheckHealth
echo.
echo === SYSTEM FILE CHECKER (SFC /SCANNOW) ===
sfc /scannow
exit /b 0
"@
        },
        [PSCustomObject]@{
            Category    = "Security, Defender & OS Repair"
            Name        = "Installed Software Inventory (64-bit & 32-bit Uninstall Registry)"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Fast, safe registry query (avoids slow/broken Win32_Product WMI) listing all installed applications, versions, publishers, and uninstall strings. [Prereqs: WinRM running, Local Admin; No external dependencies]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : None (Native Registry provider; intentionally avoids Win32_Product WMI class which triggers MSI consistency reconfiguration)
# - Services     : WinRM (WSMan) must be Running
# - Permissions  : Local Administrator on target computer
# - GPO / Network: Queries machine-wide HKLM 64-bit and WOW6432Node 32-bit Uninstall registry hives
`$regPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty -Path `$regPaths -ErrorAction SilentlyContinue |
    Where-Object { `$_.DisplayName } |
    Sort-Object DisplayName -Unique |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString |
    Format-Table -AutoSize
"@
        },
        [PSCustomObject]@{
            Category    = "Security, Defender & OS Repair"
            Name        = "Local Machine SSL/TLS Certificates Expiring Within 60 Days"
            Type        = "PowerShell"
            Parameters  = ""
            Description = "Scans Cert:\LocalMachine\My for machine certificates expiring within the next 60 days (or already expired) to prevent outage surprises. [Prereqs: WinRM + CryptSvc running, Local Admin; No external dependencies]"
            Script      = @"
# [REMOTE PREREQUISITES & DEPENDENCIES]
# - Dependencies : Built-in Microsoft.PowerShell.Security Certificate provider (Cert:\LocalMachine\My)
# - Services     : WinRM (WSMan), Cryptographic Services (CryptSvc) must be Running
# - Permissions  : Local Administrator on target computer (required to enumerate LocalMachine certificate store)
# - GPO / Network: Allow inbound WinRM (TCP 5985/5986) via Windows Firewall / GPO
`$cutoff = (Get-Date).AddDays(60)
`$certs = @(Get-ChildItem -LiteralPath 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
    Where-Object { `$_.NotAfter -le `$cutoff } |
    Sort-Object NotAfter)
if (`$certs.Count -eq 0) {
    Write-Output "No certificates in Cert:\LocalMachine\My are expiring within the next 60 days on `$env:COMPUTERNAME."
} else {
    `$certs |
        Select-Object Subject, Issuer, NotAfter, @{N='DaysRemaining';E={[math]::Round((`$_.NotAfter - (Get-Date)).TotalDays, 0)}}, Thumbprint |
        Format-Table -AutoSize
}
"@
        }
    )
}

[xml]$cannedScriptsXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="📚 Canned Scripts Library — Windows SysAdmin &amp; IT Troubleshooting" Height="700" Width="1040"
        MinHeight="560" MinWidth="860"
        WindowStartupLocation="CenterOwner" Background="#1E1E2E" Foreground="#CDD6F4"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#F5E0DC"/><Setter Property="BorderBrush" Value="#45475A"/><Setter Property="Padding" Value="6,3"/><Setter Property="Height" Value="28"/><Setter Property="VerticalContentAlignment" Value="Center"/></Style>
        <ControlTemplate x:Key="ComboBoxToggleButtonTemplate" TargetType="ToggleButton">
            <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="20"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="1" Text="▼" Foreground="#CDD6F4" FontSize="10" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Grid>
            </Border>
        </ControlTemplate>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Template="{StaticResource ComboBoxToggleButtonTemplate}"
                                          Background="#313244" BorderBrush="#45475A" BorderThickness="1"
                                          Focusable="False" ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"/>
                            <ContentPresenter x:Name="ContentSite" IsHitTestVisible="False"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="8,3,24,3"
                                              VerticalAlignment="Center" HorizontalAlignment="Left"
                                              TextElement.Foreground="#CDD6F4" TextElement.FontWeight="SemiBold"/>
                            <Popup x:Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                                <Grid x:Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="260">
                                    <Border Background="#181825" BorderBrush="#45475A" BorderThickness="1" CornerRadius="3">
                                        <ScrollViewer SnapsToDevicePixels="True">
                                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="6,4"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#A6E3A1"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#313244"/>
                    <Setter Property="Foreground" Value="#89B4FA"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="10,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#11111B"/>
            <Setter Property="Foreground" Value="#89B4FA"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="BorderBrush" Value="#313244"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>
    </Window.Resources>

    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- TOP FILTER BAR -->
        <Border Grid.Row="0" Background="#181825" BorderBrush="#313244" BorderThickness="1" CornerRadius="5" Padding="10,8" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="220"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="140"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Category:" FontWeight="SemiBold" Margin="0,0,8,0"/>
                <ComboBox x:Name="cmbCannedCategory" Grid.Column="1" Margin="0,0,14,0"/>

                <TextBlock Grid.Column="2" Text="Shell Type:" FontWeight="SemiBold" Margin="0,0,8,0"/>
                <ComboBox x:Name="cmbCannedType" Grid.Column="3" Margin="0,0,14,0">
                    <ComboBoxItem Content="All Types" IsSelected="True"/>
                    <ComboBoxItem Content="PowerShell"/>
                    <ComboBoxItem Content="Batch"/>
                </ComboBox>

                <TextBlock Grid.Column="4" Text="🔍 Search:" FontWeight="SemiBold" Margin="0,0,8,0"/>
                <TextBox x:Name="txtCannedSearch" Grid.Column="5" Margin="0,0,8,0" ToolTip="Filter by script name, command (e.g. ipconfig, gpupdate, bitlocker, sfc, netstat), or description"/>
                <Button x:Name="btnCannedClearSearch" Grid.Column="6" Content="Clear" Width="Auto" MinWidth="65" Height="28" Background="#45475A" Foreground="#CDD6F4" ToolTip="Reset category, type, and search filters"/>
            </Grid>
        </Border>

        <!-- MASTER-DETAIL BODY -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition x:Name="colCannedList" Width="430" MinWidth="300"/>
                <ColumnDefinition Width="8"/>
                <ColumnDefinition Width="*" MinWidth="360"/>
            </Grid.ColumnDefinitions>

            <!-- LEFT: CANNED SCRIPTS DATAGRID -->
            <Border Grid.Column="0" Background="#181825" BorderBrush="#313244" BorderThickness="1" CornerRadius="5" Padding="6">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="📋 Available SysAdmin &amp; IT Scripts (Double-click or Ctrl/Shift-select multiple to add)" FontWeight="Bold" Foreground="#89B4FA" Margin="4,2,4,6"/>
                    <DataGrid x:Name="dgCannedScripts" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" CanUserSortColumns="True"
                              SelectionMode="Extended" HeadersVisibility="Column" RowHeaderWidth="0"
                              Background="#181825" Foreground="#CDD6F4" RowBackground="#1E1E2E" AlternatingRowBackground="#313244"
                              GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#45475A" BorderThickness="0">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Type" Binding="{Binding Type}" Width="82"/>
                            <DataGridTextColumn Header="Category" Binding="{Binding Category}" Width="135"/>
                            <DataGridTextColumn Header="Script / Lookup Name" Binding="{Binding Name}" Width="*"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </Border>

            <GridSplitter Grid.Column="1" Width="6" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                          Background="#313244" ResizeDirection="Columns" ResizeBehavior="PreviousAndNext"
                          ShowsPreview="False" Cursor="SizeWE"
                          ToolTip="Drag left or right to resize the Canned Scripts list and Preview pane"/>

            <!-- RIGHT: SCRIPT PREVIEW & CUSTOMIZATION PANE -->
            <Border Grid.Column="2" Background="#181825" BorderBrush="#313244" BorderThickness="1" CornerRadius="5" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <TextBlock Grid.Row="0" Text="🛠️ Step Preview &amp; Pre-Insert Customization" FontWeight="Bold" Foreground="#F9E2AF" Margin="0,0,0,8"/>

                    <!-- Step Name & Type -->
                    <Grid Grid.Row="1" Margin="0,0,0,8">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="85"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="105"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="Step Name:"/>
                        <TextBox x:Name="txtCannedName" Grid.Column="1" Margin="0,0,10,0"/>
                        <TextBlock Grid.Column="2" Text="Type:" Margin="0,0,6,0"/>
                        <TextBox x:Name="txtCannedTypeBadge" Grid.Column="3" IsReadOnly="True" Background="#11111B" Foreground="#89DCEB" FontWeight="Bold" HorizontalContentAlignment="Center"/>
                    </Grid>

                    <!-- Parameters -->
                    <Grid Grid.Row="2" Margin="0,0,0,8">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="85"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="Parameters:"/>
                        <TextBox x:Name="txtCannedParams" Grid.Column="1" ToolTip="Optional arguments passed to the script during remote execution"/>
                    </Grid>

                    <!-- Description Box -->
                    <Border Grid.Row="3" Background="#11111B" BorderBrush="#313244" BorderThickness="1" CornerRadius="4" Padding="8,6" Margin="0,0,0,8">
                        <TextBlock x:Name="txtCannedDesc" Text="Select a canned script on the left to inspect its description and code." Foreground="#A6ADC8" TextWrapping="Wrap" FontSize="11.5"/>
                    </Border>

                    <TextBlock Grid.Row="4" Text="Script Content (Editable before adding to package):" Foreground="#A6ADC8" Margin="0,0,0,4"/>

                    <!-- Multiline Script TextBox (LL-005 Compliant) -->
                    <TextBox x:Name="txtCannedScript" Grid.Row="5" Background="#313244" Foreground="#F5E0DC" BorderBrush="#45475A"
                             FontFamily="Consolas" FontSize="12" AcceptsReturn="True" AcceptsTab="True"
                             Height="Auto" MinHeight="220" VerticalAlignment="Stretch" VerticalContentAlignment="Top" Padding="8,6"
                             VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>
                </Grid>
            </Border>
        </Grid>

        <!-- BOTTOM ACTION BAR -->
        <Grid Grid.Row="2" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="lblCannedCount" Grid.Column="0" Text="Showing 0 scripts" Foreground="#A6ADC8" FontSize="12"/>
            <Button x:Name="btnCannedOpenEditor" Grid.Column="1" Content="✏️ Open in Step Editor..." Width="Auto" MinWidth="155" Margin="0,0,8,0" Background="#89B4FA" Foreground="#11111B" FontWeight="SemiBold" ToolTip="Open selected script inside the full Step Editor modal"/>
            <Button x:Name="btnCannedAddStay" Grid.Column="2" Content="＋ Add &amp; Keep Open" Width="Auto" MinWidth="140" Margin="0,0,8,0" Background="#89DCEB" Foreground="#11111B" FontWeight="Bold" ToolTip="Add this script as a package step and keep the Canned Scripts library open"/>
            <Button x:Name="btnCannedAddClose" Grid.Column="3" Content="✔ Add to Package Steps" Width="Auto" MinWidth="165" Margin="0,0,8,0" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" ToolTip="Add this script to the current deployment package and close"/>
            <Button x:Name="btnCannedClose" Grid.Column="4" Content="Close" Width="Auto" MinWidth="85" Background="#45475A" Foreground="#CDD6F4"/>
        </Grid>
    </Grid>
</Window>
"@

function Show-CannedScriptsDialog {
    $rdr = New-Object System.Xml.XmlNodeReader $cannedScriptsXaml
    $dlg = [System.Windows.Markup.XamlReader]::Load($rdr)
    $dlg.Owner = $window

    $cmbCannedCategory   = $dlg.FindName("cmbCannedCategory")
    $cmbCannedType       = $dlg.FindName("cmbCannedType")
    $txtCannedSearch     = $dlg.FindName("txtCannedSearch")
    $btnCannedClearSearch= $dlg.FindName("btnCannedClearSearch")
    $dgCannedScripts     = $dlg.FindName("dgCannedScripts")
    $txtCannedName       = $dlg.FindName("txtCannedName")
    $txtCannedTypeBadge  = $dlg.FindName("txtCannedTypeBadge")
    $txtCannedParams     = $dlg.FindName("txtCannedParams")
    $txtCannedDesc       = $dlg.FindName("txtCannedDesc")
    $txtCannedScript     = $dlg.FindName("txtCannedScript")
    $lblCannedCount      = $dlg.FindName("lblCannedCount")
    $btnCannedOpenEditor = $dlg.FindName("btnCannedOpenEditor")
    $btnCannedAddStay    = $dlg.FindName("btnCannedAddStay")
    $btnCannedAddClose   = $dlg.FindName("btnCannedAddClose")
    $btnCannedClose      = $dlg.FindName("btnCannedClose")

    $allCatalog = @(Get-CannedScriptsCatalog)
    $filteredCatalog = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $dgCannedScripts.ItemsSource = $filteredCatalog

    # Populate Categories ComboBox
    $allCatItem = New-Object System.Windows.Controls.ComboBoxItem
    $allCatItem.Content = "All Categories"
    $allCatItem.IsSelected = $true
    [void]$cmbCannedCategory.Items.Add($allCatItem)

    $categories = @($allCatalog | Select-Object -ExpandProperty Category -Unique)
    foreach ($cat in $categories) {
        $ci = New-Object System.Windows.Controls.ComboBoxItem
        $ci.Content = $cat
        [void]$cmbCannedCategory.Items.Add($ci)
    }

    $updateFilter = {
        $selCatObj  = $cmbCannedCategory.SelectedItem
        $selCat     = if ($selCatObj -and $selCatObj.Content) { [string]$selCatObj.Content } else { "All Categories" }
        $selTypeObj = $cmbCannedType.SelectedItem
        $selType    = if ($selTypeObj -and $selTypeObj.Content) { [string]$selTypeObj.Content } else { "All Types" }
        $query      = if ($txtCannedSearch.Text) { $txtCannedSearch.Text.Trim() } else { "" }

        $filteredCatalog.Clear()
        foreach ($item in $allCatalog) {
            if ($selCat -ne "All Categories" -and $item.Category -ne $selCat) { continue }
            if ($selType -ne "All Types" -and $item.Type -ne $selType) { continue }
            if (-not [string]::IsNullOrWhiteSpace($query)) {
                $matchName   = $item.Name.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                $matchCat    = $item.Category.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                $matchDesc   = $item.Description.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                $matchScript = $item.Script.IndexOf($query, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                if (-not ($matchName -or $matchCat -or $matchDesc -or $matchScript)) { continue }
            }
            [void]$filteredCatalog.Add($item)
        }

        $lblCannedCount.Text = "Showing $($filteredCatalog.Count) of $($allCatalog.Count) canned scripts"
        if ($filteredCatalog.Count -gt 0) {
            $dgCannedScripts.SelectedIndex = 0
        } else {
            $txtCannedName.Text      = ""
            $txtCannedTypeBadge.Text = ""
            $txtCannedParams.Text    = ""
            $txtCannedDesc.Text      = "No canned scripts match the current filter."
            $txtCannedScript.Text    = ""
        }
    }

    $dgCannedScripts.Add_SelectionChanged({
        $sel = $dgCannedScripts.SelectedItem
        if ($sel) {
            $txtCannedName.Text      = $sel.Name
            $txtCannedTypeBadge.Text = $sel.Type
            $txtCannedParams.Text    = $sel.Parameters
            $txtCannedDesc.Text      = "[$($sel.Category)] $($sel.Description)"
            $txtCannedScript.Text    = $sel.Script
        }
    })

    $cmbCannedCategory.Add_SelectionChanged($updateFilter)
    $cmbCannedType.Add_SelectionChanged($updateFilter)
    $txtCannedSearch.Add_TextChanged($updateFilter)

    $btnCannedClearSearch.Add_Click({
        $cmbCannedCategory.SelectedIndex = 0
        $cmbCannedType.SelectedIndex     = 0
        $txtCannedSearch.Text            = ""
        & $updateFilter
    })

    $addCurrentSelectionToPackage = {
        param([bool]$CloseAfterAdd)
        $selectedItems = @($dgCannedScripts.SelectedItems)
        if ($selectedItems.Count -gt 1) {
            $lastAdded = $null
            foreach ($item in $selectedItems) {
                $stepType = if ($item.Type -eq "Batch") { "Batch" } else { "PowerShell" }
                $newStep = New-StepObject -Name ([string]$item.Name).Trim() `
                                          -Type $stepType `
                                          -Script ([string]$item.Script) `
                                          -Parameters ([string]$item.Parameters).Trim()
                $script:StepsCollection.Add($newStep)
                $lastAdded = $newStep
            }
            Renumber-Steps
            if ($lastAdded) { $dgSteps.SelectedItem = $lastAdded }
            $txtPkgName.Text = "(Custom Package)"
            $lblCannedCount.Text = "Added $($selectedItems.Count) canned scripts to package (Total Steps: $($script:StepsCollection.Count))"
            if ($CloseAfterAdd) {
                $dlg.DialogResult = $true
                $dlg.Close()
            }
            return
        }

        if ([string]::IsNullOrWhiteSpace($txtCannedName.Text) -or [string]::IsNullOrWhiteSpace($txtCannedScript.Text)) {
            [System.Windows.MessageBox]::Show("Please select a canned script with a valid name and script body.", "Canned Scripts", "OK", "Warning")
            return
        }
        $stepType = if ($txtCannedTypeBadge.Text -eq "Batch") { "Batch" } else { "PowerShell" }
        $newStep = New-StepObject -Name $txtCannedName.Text.Trim() `
                                  -Type $stepType `
                                  -Script $txtCannedScript.Text `
                                  -Parameters $txtCannedParams.Text.Trim()
        $script:StepsCollection.Add($newStep)
        Renumber-Steps
        $dgSteps.SelectedItem = $newStep
        if ($script:StepsCollection.Count -eq 1) {
            $txtPkgName.Text = $newStep.Name
        } else {
            $txtPkgName.Text = "(Custom Package)"
        }
        $lblCannedCount.Text = "Added '$($newStep.Name)' to package (Total Steps: $($script:StepsCollection.Count))"
        if ($CloseAfterAdd) {
            $dlg.DialogResult = $true
            $dlg.Close()
        }
    }
    $btnCannedAddStay.Add_Click({
        & $addCurrentSelectionToPackage $false
    })

    $btnCannedAddClose.Add_Click({
        & $addCurrentSelectionToPackage $true
    })

    $dgCannedScripts.Add_MouseDoubleClick({
        if ($dgCannedScripts.SelectedItem) {
            & $addCurrentSelectionToPackage $true
        }
    })

    $btnCannedOpenEditor.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtCannedName.Text)) { return }
        $stepType = if ($txtCannedTypeBadge.Text -eq "Batch") { "Batch" } else { "PowerShell" }
        $tempStep = New-StepObject -Name $txtCannedName.Text.Trim() `
                                   -Type $stepType `
                                   -Script $txtCannedScript.Text `
                                   -Parameters $txtCannedParams.Text.Trim()
        $edited = Show-StepEditor -Existing $tempStep
        if ($edited) {
            $script:StepsCollection.Add($edited)
            Renumber-Steps
            $dgSteps.SelectedItem = $edited
            if ($script:StepsCollection.Count -eq 1) {
                $txtPkgName.Text = $edited.Name
            } else {
                $txtPkgName.Text = "(Custom Package)"
            }
            $dlg.DialogResult = $true
            $dlg.Close()
        }
    })

    $btnCannedClose.Add_Click({
        $dlg.DialogResult = $false
        $dlg.Close()
    })

    & $updateFilter
    $colCannedList = $dlg.FindName("colCannedList")
    Register-ChildWindowLayoutPersistence -Dialog $dlg -WindowKey "CannedScripts" -LeftColumn $colCannedList -LeftColumnProp "ListPaneWidth"
    [void]$dlg.ShowDialog()
}

function Rename-SelectedStep {
    $sel = $dgSteps.SelectedItem
    if (-not $sel) {
        [System.Windows.MessageBox]::Show("Please select a step/task to rename.", "Rename Step", "OK", "Information")
        return
    }
    $newName = Show-FolderInputDialog -Title "Rename Deployment Task / Step" -Prompt "Enter new name for step '$($sel.Name)':" -DefaultValue $sel.Name
    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $sel.Name) { return }
    $sel.Name = $newName.Trim()
    Renumber-Steps
    $dgSteps.Items.Refresh()
    $lblStatus.Text = "Renamed step #$($sel.Order) to '$($sel.Name)'."
}

$menuEditStep.Add_Click({ Edit-SelectedStep })
if ($menuRenameStep) { $menuRenameStep.Add_Click({ Rename-SelectedStep }) }
$menuMoveUp.Add_Click({ Move-StepUp })
$menuMoveDown.Add_Click({ Move-StepDown })
$menuRemoveStep.Add_Click({ Remove-SelectedStep })
$menuClearSteps.Add_Click({ Clear-AllSteps })
$btnClearSteps.Add_Click({ Clear-AllSteps })

$dgSteps.Add_MouseDoubleClick({
    if ($dgSteps.SelectedItem) { Edit-SelectedStep }
})

$dgSteps.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::Delete) { Remove-SelectedStep }
    elseif ($_.Key -eq [System.Windows.Input.Key]::F2) { Rename-SelectedStep }
})

# ==========================================
# 4. PACKAGE LIBRARY ENGINE
# ==========================================
$script:LibraryPath = Join-Path $script:SettingsDir "package_library.json"
$script:PackageLibrary = [System.Collections.Generic.List[PSCustomObject]]::new()

function Load-PackageLibrary {
    $script:PackageLibrary.Clear()
    if (Test-Path $script:LibraryPath) {
        try {
            $rawJson = [System.IO.File]::ReadAllText($script:LibraryPath, [System.Text.Encoding]::UTF8)
            $parsed = ConvertFrom-Json -InputObject $rawJson -ErrorAction Stop
            foreach ($folder in $parsed.Folders) {
                $pkgList = [System.Collections.Generic.List[PSCustomObject]]::new()
                foreach ($p in $folder.Packages) {
                    $stList = [System.Collections.Generic.List[PSCustomObject]]::new()
                    foreach ($st in $p.Steps) {
                        $stList.Add((New-StepObject -Name "$($st.Name)" `
                                                   -Type "$($st.Type)" `
                                                   -Script "$($st.Script)" `
                                                   -Parameters "$($st.Parameters)" `
                                                   -PayloadPath "$($st.PayloadPath)" `
                                                   -IncludeFolder ([bool]$st.IncludeFolder) `
                                                   -SilentInstall ([bool]$st.SilentInstall) `
                                                   -PauseSeconds ([int]$st.PauseSeconds)))
                    }
                    $pkgList.Add([PSCustomObject]@{
                        Name  = [string]$p.Name
                        Steps = $stList
                    })
                }
                $script:PackageLibrary.Add([PSCustomObject]@{
                    Name     = [string]$folder.Name
                    Packages = $pkgList
                })
            }
        } catch {}
    }

    # Initialize default structure if empty
    if ($script:PackageLibrary.Count -eq 0) {
        $defaultFolders = @("General", "Software Installers", "Maintenance")
        foreach ($f in $defaultFolders) {
            $script:PackageLibrary.Add([PSCustomObject]@{
                Name     = $f
                Packages = [System.Collections.Generic.List[PSCustomObject]]::new()
            })
        }
    }
    Refresh-LibraryTreeView
}

function Save-PackageLibrary {
    try {
        $dto = [PSCustomObject]@{
            Folders = $script:PackageLibrary
        }
        $json = ConvertTo-Json -InputObject $dto -Depth 6
        [System.IO.File]::WriteAllText($script:LibraryPath, $json, [System.Text.Encoding]::UTF8)

        if (-not (Test-Path $script:PackagesDir)) {
            [void][System.IO.Directory]::CreateDirectory($script:PackagesDir)
        }
        foreach ($folder in $script:PackageLibrary) {
            $safeFolder = ($folder.Name -replace '[\\/:*?"<>|]', '_')
            foreach ($pkg in $folder.Packages) {
                $safeName = ($pkg.Name -replace '[\\/:*?"<>|]', '_')
                $pkgFile = Join-Path $script:PackagesDir "${safeFolder}_${safeName}.json"
                $pkgDto = [PSCustomObject]@{
                    PackageName = $pkg.Name
                    Folder      = $folder.Name
                    Steps       = $pkg.Steps
                }
                $pkgJson = ConvertTo-Json -InputObject $pkgDto -Depth 6
                [System.IO.File]::WriteAllText($pkgFile, $pkgJson, [System.Text.Encoding]::UTF8)
            }
        }
    } catch {
        [System.Windows.MessageBox]::Show("Failed to save package library: $($_.Exception.Message)", "Library Error", "OK", "Error")
    }
}

function Get-SelectedLibraryFolder {
    if ($null -ne $txtPkgFolder.SelectedItem -and -not [string]::IsNullOrWhiteSpace([string]$txtPkgFolder.SelectedItem)) {
        return ([string]$txtPkgFolder.SelectedItem).Trim()
    }
    if (-not [string]::IsNullOrWhiteSpace($txtPkgFolder.Text)) {
        return $txtPkgFolder.Text.Trim()
    }
    return "General"
}

function Set-SelectedLibraryFolder([string]$FolderName) {
    $target = if ([string]::IsNullOrWhiteSpace($FolderName)) { "General" } else { $FolderName.Trim() }
    if (-not $txtPkgFolder.Items.Contains($target)) {
        [void]$txtPkgFolder.Items.Add($target)
    }
    $txtPkgFolder.SelectedItem = $target
}

function Update-LibrarySelectionVisuals {
    if (-not $tvLibrary) { return }
    $brushConv  = [System.Windows.Media.BrushConverter]::new()
    $fgFolder   = $brushConv.ConvertFromString("#CBA6F7")
    $fgPkg      = $brushConv.ConvertFromString("#CDD6F4")
    $fgSelected = $brushConv.ConvertFromString("#FFFFFF")
    $bgSelected = $brushConv.ConvertFromString("#2563EB")
    $bgClear    = [System.Windows.Media.Brushes]::Transparent

    foreach ($fNode in $tvLibrary.Items) {
        if (-not ($fNode -is [System.Windows.Controls.TreeViewItem])) { continue }
        if ($fNode.IsSelected) {
            $fNode.Foreground = $fgSelected
            $fNode.Background = $bgSelected
        } else {
            $fNode.Foreground = $fgFolder
            $fNode.Background = $bgClear
        }
        foreach ($pNode in $fNode.Items) {
            if (-not ($pNode -is [System.Windows.Controls.TreeViewItem])) { continue }
            if ($pNode.IsSelected) {
                $pNode.Foreground = $fgSelected
                $pNode.Background = $bgSelected
            } else {
                $pNode.Foreground = $fgPkg
                $pNode.Background = $bgClear
            }
        }
    }
}

function Sync-DeployPackagesList {
    # Deployment panel now displays Running Deployments & Deployment History in $script:DeployPackagesCollection
    if ($dgDeployPackages) {
        try { $dgDeployPackages.Items.Refresh() } catch {}
    }
}

function New-Win11MenuItem {
    param(
        [Parameter(Mandatory)][string]$Header,
        [string]$InputGestureText = "",
        [string]$Glyph = "",
        [string]$ColorHex = "#CDD6F4",
        [string]$ForegroundHex = "",
        $Tag = $null,
        [scriptblock]$OnClick = $null
    )
    $mi = New-Object System.Windows.Controls.MenuItem
    $mi.Header = $Header
    if (-not [string]::IsNullOrWhiteSpace($InputGestureText)) {
        $mi.InputGestureText = $InputGestureText
    }
    if (-not [string]::IsNullOrWhiteSpace($Glyph)) {
        $mi.Icon = New-Win11MenuIcon -Glyph $Glyph -ColorHex $ColorHex
    }
    if (-not [string]::IsNullOrWhiteSpace($ForegroundHex)) {
        $mi.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ForegroundHex)
    }
    if ($null -ne $Tag) {
        $mi.Tag = $Tag
    }
    if ($null -ne $OnClick) {
        $mi.Add_Click($OnClick)
    }
    return $mi
}

function Get-OrCreateLibraryFolder {
    param([string]$FolderName = "General")
    $resolved = if ([string]::IsNullOrWhiteSpace($FolderName)) { "General" } else { $FolderName.Trim() }
    $folderObj = $script:PackageLibrary | Where-Object { $_.Name -ieq $resolved } | Select-Object -First 1
    if (-not $folderObj) {
        $folderObj = [PSCustomObject]@{
            Name     = $resolved
            Packages = [System.Collections.Generic.List[PSCustomObject]]::new()
        }
        [void]$script:PackageLibrary.Add($folderObj)
    }
    return $folderObj
}

function Save-PackageToLibraryFolder {
    param(
        [Parameter(Mandatory)][string]$PackageName,
        [string]$FolderName = "General",
        [Parameter(Mandatory)]$Steps
    )
    $targetFolder = Get-OrCreateLibraryFolder -FolderName $FolderName
    $stList = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($st in $Steps) {
        if ($null -eq $st) { continue }
        $stList.Add((New-StepObject -Name $st.Name `
                                    -Type $st.Type `
                                    -Script $st.Script `
                                    -Parameters $st.Parameters `
                                    -PayloadPath $st.PayloadPath `
                                    -IncludeFolder ([bool]$st.IncludeFolder) `
                                    -SilentInstall ([bool]$st.SilentInstall) `
                                    -PauseSeconds ([int]$st.PauseSeconds)))
    }
    $existingPkg = $targetFolder.Packages | Where-Object { $_.Name -ieq $PackageName } | Select-Object -First 1
    if ($existingPkg) {
        $existingPkg.Steps = $stList
    } else {
        [void]$targetFolder.Packages.Add([PSCustomObject]@{
            Name  = $PackageName
            Steps = $stList
        })
    }
    Save-PackageLibrary
    Refresh-LibraryTreeView -SelectPackageName $PackageName
    Update-ActivePackageBanner
    return $targetFolder
}

function Refresh-LibraryTreeView {
    param([string]$SelectPackageName = $null)
    $currentSelectedFolder = Get-SelectedLibraryFolder
    $tvLibrary.Items.Clear()
    $nodeToSelect = $null
    $brushConv   = [System.Windows.Media.BrushConverter]::new()
    $folderBrush = $brushConv.ConvertFromString("#CBA6F7")
    $pkgBrush    = $brushConv.ConvertFromString("#CDD6F4")
    $editGlyph   = [string][char]0x270F

    foreach ($folder in $script:PackageLibrary) {
        $fNode = New-Object System.Windows.Controls.TreeViewItem
        $fNode.Header = "📁 $($folder.Name)"
        $fNode.Tag = @{ Type = "Folder"; Folder = $folder }
        $fNode.IsExpanded = $true
        $fNode.Foreground = $folderBrush

        # Windows 11 Right-Click ContextMenu on Folder Node
        $ctxFolder = New-Win11ContextMenu
        [void]$ctxFolder.Items.Add((New-Win11MenuItem -Header "New Package in '$($folder.Name)'" -InputGestureText "Ctrl+N" -Glyph "+" -ColorHex "#89B4FA" -Tag $folder.Name -OnClick {
            param($s, $e)
            Set-SelectedLibraryFolder ([string]$s.Tag)
            $txtPkgName.Text = "New Deployment Package"
            $script:StepsCollection.Clear()
            Renumber-Steps
            Show-PackageStepsModal
        }))
        [void]$ctxFolder.Items.Add((New-Win11MenuItem -Header "Create New Library Folder..." -Glyph "📁" -ColorHex "#CBA6F7" -OnClick {
            $btnNewFolder.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }))
        if ($folder.Name -ne "General") {
            [void]$ctxFolder.Items.Add((New-Win11MenuItem -Header "Rename Folder..." -InputGestureText "F2" -Glyph $editGlyph -ColorHex "#F9E2AF" -Tag $folder -OnClick {
                param($s, $e)
                Rename-LibraryFolder -FolderObj $s.Tag
            }))
        }
        [void]$ctxFolder.Items.Add((New-Object System.Windows.Controls.Separator))
        [void]$ctxFolder.Items.Add((New-Win11MenuItem -Header "Import Package..." -InputGestureText "JSON" -Glyph "📥" -ColorHex "#A6E3A1" -Tag $folder.Name -OnClick {
            param($s, $e)
            Invoke-ImportLibraryPackage -TargetFolderName ([string]$s.Tag)
        }))
        [void]$ctxFolder.Items.Add((New-Win11MenuItem -Header "Export Package..." -InputGestureText "JSON" -Glyph "📤" -ColorHex "#89B4FA" -OnClick {
            Invoke-ExportLibraryPackage
        }))
        if ($folder.Name -ne "General") {
            [void]$ctxFolder.Items.Add((New-Object System.Windows.Controls.Separator))
            [void]$ctxFolder.Items.Add((New-Win11MenuItem -Header "Delete Folder '$($folder.Name)'" -InputGestureText "Del" -Glyph "🗑" -ColorHex "#F38BA8" -ForegroundHex "#F38BA8" -Tag $fNode -OnClick {
                param($s, $e)
                $s.Tag.IsSelected = $true
                $btnDeletePkg.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
            }))
        }
        $fNode.ContextMenu = $ctxFolder

        foreach ($pkg in $folder.Packages) {
            $pNode = New-Object System.Windows.Controls.TreeViewItem
            $pNode.Header = "📦 $($pkg.Name)"
            $pNode.Tag = @{ Type = "Package"; Folder = $folder; Package = $pkg }
            $pNode.Foreground = $pkgBrush
            $pNode.Add_MouseDoubleClick({
                param($s, $e)
                if ($s.Tag -and $s.Tag.Type -eq 'Package') {
                    Load-PackageIntoEditor -Package $s.Tag.Package -FolderName $s.Tag.Folder.Name
                    $e.Handled = $true
                    Show-PackageStepsModal
                }
            })

            # Windows 11 Right-Click ContextMenu on Package Node
            $ctxPkg = New-Win11ContextMenu
            $pkgNodeContext = @{ Pkg = $pkg; FolderName = $folder.Name; Folder = $folder }
            [void]$ctxPkg.Items.Add((New-Win11MenuItem -Header "Select Package for Deployment" -InputGestureText "Click" -Glyph "🚀" -ColorHex "#A6E3A1" -Tag $pkgNodeContext -OnClick {
                param($s, $e)
                Load-PackageIntoEditor -Package $s.Tag.Pkg -FolderName $s.Tag.FolderName
            }))
            [void]$ctxPkg.Items.Add((New-Win11MenuItem -Header "Edit Package Steps..." -InputGestureText "Double-Click" -Glyph "📦" -ColorHex "#89B4FA" -Tag $pkgNodeContext -OnClick {
                param($s, $e)
                Load-PackageIntoEditor -Package $s.Tag.Pkg -FolderName $s.Tag.FolderName
                Show-PackageStepsModal
            }))
            [void]$ctxPkg.Items.Add((New-Win11MenuItem -Header "Rename Package / Task..." -InputGestureText "F2" -Glyph $editGlyph -ColorHex "#F9E2AF" -Tag $pkgNodeContext -OnClick {
                param($s, $e)
                Rename-LibraryPackage -PackageObj $s.Tag.Pkg -FolderObj $s.Tag.Folder
            }))

            # Submenu: Move Package to Folder
            $miMoveTo = New-Win11MenuItem -Header "Move to Folder" -Glyph "📂" -ColorHex "#CBA6F7"
            foreach ($destF in $script:PackageLibrary) {
                if ($destF.Name -eq $folder.Name) { continue }
                [void]$miMoveTo.Items.Add((New-Win11MenuItem -Header $destF.Name -Glyph "📁" -ColorHex "#A6ADC8" -Tag @{ PkgName = $pkg.Name; DestFolder = $destF.Name } -OnClick {
                    param($s, $e)
                    [void](Move-LibraryPackage -PackageName $s.Tag.PkgName -TargetFolder $s.Tag.DestFolder)
                }))
            }
            if ($miMoveTo.Items.Count -gt 0) {
                [void]$ctxPkg.Items.Add($miMoveTo)
            }

            [void]$ctxPkg.Items.Add((New-Object System.Windows.Controls.Separator))
            [void]$ctxPkg.Items.Add((New-Win11MenuItem -Header "Import Package..." -InputGestureText "JSON" -Glyph "📥" -ColorHex "#A6E3A1" -Tag $folder.Name -OnClick {
                param($s, $e)
                Invoke-ImportLibraryPackage -TargetFolderName ([string]$s.Tag)
            }))
            [void]$ctxPkg.Items.Add((New-Win11MenuItem -Header "Export Package..." -InputGestureText "JSON" -Glyph "📤" -ColorHex "#89B4FA" -Tag $pkgNodeContext -OnClick {
                param($s, $e)
                Invoke-ExportLibraryPackage -Package $s.Tag.Pkg -FolderName $s.Tag.FolderName
            }))
            [void]$ctxPkg.Items.Add((New-Object System.Windows.Controls.Separator))
            [void]$ctxPkg.Items.Add((New-Win11MenuItem -Header "Delete Package '$($pkg.Name)'" -InputGestureText "Del" -Glyph "🗑" -ColorHex "#F38BA8" -ForegroundHex "#F38BA8" -Tag $pNode -OnClick {
                param($s, $e)
                $s.Tag.IsSelected = $true
                $btnDeletePkg.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
            }))
            $pNode.ContextMenu = $ctxPkg
            if (-not [string]::IsNullOrWhiteSpace($SelectPackageName) -and $pkg.Name -eq $SelectPackageName) {
                $nodeToSelect = $pNode
            }
            [void]$fNode.Items.Add($pNode)
        }
        [void]$tvLibrary.Items.Add($fNode)
    }
    if ($nodeToSelect) {
        $nodeToSelect.IsSelected = $true
    }

    # Synchronize Library Folder ComboBox items with Package Library folders
    $folderNames = @($script:PackageLibrary | ForEach-Object {
        if ($_ -is [string]) { $_ } else { [string]$_.Name }
    } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    if ($folderNames.Count -eq 0) { $folderNames = @("General") }
    $txtPkgFolder.Items.Clear()
    foreach ($fn in $folderNames) {
        [void]$txtPkgFolder.Items.Add($fn)
    }
    if ($txtPkgFolder.Items.Contains($currentSelectedFolder)) {
        $txtPkgFolder.SelectedItem = $currentSelectedFolder
    } elseif ($txtPkgFolder.Items.Count -gt 0) {
        $txtPkgFolder.SelectedIndex = 0
    }

    Update-LibrarySelectionVisuals
    Sync-DeployPackagesList
    Update-ActivePackageBanner
}

function Refresh-LibraryTree {
    param([string]$SelectPackageName = $null)
    Refresh-LibraryTreeView -SelectPackageName $SelectPackageName
}

function Load-PackageIntoEditor {
    param($Package, $FolderName)
    if (-not $Package) { return }
    $txtPkgName.Text = $Package.Name
    if (-not [string]::IsNullOrWhiteSpace($FolderName)) {
        Set-SelectedLibraryFolder $FolderName
    }
    $script:StepsCollection.Clear()
    foreach ($st in $Package.Steps) {
        $copy = New-StepObject -Name $st.Name `
                               -Type $st.Type `
                               -Script $st.Script `
                               -Parameters $st.Parameters `
                               -PayloadPath $st.PayloadPath `
                               -IncludeFolder ([bool]$st.IncludeFolder) `
                               -SilentInstall ([bool]$st.SilentInstall) `
                               -PauseSeconds ([int]$st.PauseSeconds)
        $script:StepsCollection.Add($copy)
    }
    Renumber-Steps
    Update-ActivePackageBanner
    $lblStatus.Text = "Loaded package '$($Package.Name)' from library folder '$FolderName'."
}

$tvLibrary.Add_SelectedItemChanged({
    Update-LibrarySelectionVisuals
    $sel = $tvLibrary.SelectedItem
    if ($sel -and $sel.Tag) {
        if ($sel.Tag.Type -eq 'Package') {
            Load-PackageIntoEditor -Package $sel.Tag.Package -FolderName $sel.Tag.Folder.Name
        } elseif ($sel.Tag.Type -eq 'Folder') {
            Set-SelectedLibraryFolder $sel.Tag.Folder.Name
            Update-ActivePackageBanner
        }
    }
})
$tvLibrary.Add_LostKeyboardFocus({ Update-LibrarySelectionVisuals })
$tvLibrary.Add_GotKeyboardFocus({ Update-LibrarySelectionVisuals })
function Get-TreeViewItemFromSource {
    param($sourceObj)
    $curr = $sourceObj
    while ($curr -ne $null -and -not ($curr -is [System.Windows.Controls.TreeViewItem])) {
        if ($curr -is [System.Windows.Media.Visual] -or $curr -is [System.Windows.Media.Media3D.Visual3D]) {
            $curr = [System.Windows.Media.VisualTreeHelper]::GetParent($curr)
        } elseif ($curr -is [System.Windows.FrameworkContentElement]) {
            $curr = $curr.Parent
        } else {
            break
        }
    }
    if ($curr -is [System.Windows.Controls.TreeViewItem]) {
        return $curr
    }
    return $null
}

function Move-LibraryPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$PackageName,
        [Parameter(Mandatory=$true)][string]$TargetFolder,
        [string]$BeforePackageName = $null
    )

    if ([string]::IsNullOrWhiteSpace($PackageName) -or [string]::IsNullOrWhiteSpace($TargetFolder)) {
        return $false
    }

    # Locate package across folders
    $foundPkg = $null
    $sourceFolderObj = $null
    foreach ($f in $script:PackageLibrary) {
        $idx = -1
        for ($i = 0; $i -lt $f.Packages.Count; $i++) {
            if ($f.Packages[$i].Name -eq $PackageName) {
                $foundPkg = $f.Packages[$i]
                $sourceFolderObj = $f
                $idx = $i
                break
            }
        }
        if ($foundPkg) {
            # Remove from source folder's package list, preserving folder node
            $f.Packages.RemoveAt($idx)
            break
        }
    }

    if (-not $foundPkg) {
        return $false
    }

    # Locate or create target folder
    $targetFolderObj = $null
    foreach ($f in $script:PackageLibrary) {
        if ($f.Name -eq $TargetFolder) {
            $targetFolderObj = $f
            break
        }
    }
    if (-not $targetFolderObj) {
        $targetFolderObj = [PSCustomObject]@{
            Name     = $TargetFolder
            Packages = [System.Collections.Generic.List[psobject]]::new()
        }
        $script:PackageLibrary.Add($targetFolderObj)
    }

    # Insert or append package
    $inserted = $false
    if (-not [string]::IsNullOrWhiteSpace($BeforePackageName)) {
        for ($i = 0; $i -lt $targetFolderObj.Packages.Count; $i++) {
            if ($targetFolderObj.Packages[$i].Name -eq $BeforePackageName) {
                $targetFolderObj.Packages.Insert($i, $foundPkg)
                $inserted = $true
                break
            }
        }
    }
    if (-not $inserted) {
        $targetFolderObj.Packages.Add($foundPkg)
    }

    # Clean up old disk JSON file if folder changed
    if ($sourceFolderObj.Name -ne $targetFolderObj.Name -and (Test-Path $script:PackagesDir)) {
        $oldSafeFolder = ($sourceFolderObj.Name -replace '[\\/:*?"<>|]', '_')
        $safePkgName = ($foundPkg.Name -replace '[\\/:*?"<>|]', '_')
        $oldPkgFile = Join-Path $script:PackagesDir "${oldSafeFolder}_${safePkgName}.json"
        if (Test-Path -LiteralPath $oldPkgFile) {
            try { Remove-Item -LiteralPath $oldPkgFile -Force -ErrorAction SilentlyContinue } catch {}
        }
    }

    # Persist library and disk files
    Save-PackageLibrary

    # Refresh UI tree
    Refresh-LibraryTreeView -SelectPackageName $PackageName

    # Update active editor folder if currently editing this package
    if ($txtPkgName.Text.Trim() -eq $PackageName) {
        Set-SelectedLibraryFolder $TargetFolder
    }

    $lblStatus.Text = "Moved package '$PackageName' to folder '$TargetFolder'."
    return $true
}

# Drag and Drop handlers for Package Library
$script:dragStartPoint = $null
$script:draggedLibraryNode = $null

$tvLibrary.Add_PreviewMouseLeftButtonDown({
    $script:dragStartPoint = $_.GetPosition($tvLibrary)
    $script:draggedLibraryNode = $null
    $item = Get-TreeViewItemFromSource $_.OriginalSource
    if ($item -and $item.Tag -and $item.Tag.Type -eq 'Package') {
        $script:draggedLibraryNode = $item
    }
})

$tvLibrary.Add_PreviewMouseMove({
    if ($_.LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed -and $script:draggedLibraryNode -ne $null -and $script:dragStartPoint -ne $null) {
        $currentPos = $_.GetPosition($tvLibrary)
        $diff = $script:dragStartPoint - $currentPos
        if ([Math]::Abs($diff.X) -ge [System.Windows.SystemParameters]::MinimumHorizontalDragDistance -or
            [Math]::Abs($diff.Y) -ge [System.Windows.SystemParameters]::MinimumVerticalDragDistance) {
            $nodeToDrag = $script:draggedLibraryNode
            $script:dragStartPoint = $null
            $script:draggedLibraryNode = $null
            [void][System.Windows.DragDrop]::DoDragDrop($tvLibrary, $nodeToDrag, [System.Windows.DragDropEffects]::Move)
        }
    }
})

$tvLibrary.Add_DragOver({
    $_.Effects = [System.Windows.DragDropEffects]::None
    $targetItem = Get-TreeViewItemFromSource $_.OriginalSource
    if ($targetItem -and $targetItem.Tag) {
        $_.Effects = [System.Windows.DragDropEffects]::Move
    }
    $_.Handled = $true
})

$tvLibrary.Add_Drop({
    $targetItem = Get-TreeViewItemFromSource $_.OriginalSource
    if (-not $targetItem -or -not $targetItem.Tag) {
        $_.Handled = $true
        return
    }

    $droppedObj = $_.Data.GetData([System.Windows.Controls.TreeViewItem])
    if (-not $droppedObj -or -not $droppedObj.Tag -or $droppedObj.Tag.Type -ne 'Package') {
        $_.Handled = $true
        return
    }

    $draggedPkg = $droppedObj.Tag.Package
    $targetTag = $targetItem.Tag

    $targetFolder = $null
    $beforePkgName = $null

    if ($targetTag.Type -eq 'Folder') {
        $targetFolder = $targetTag.Folder.Name
    } elseif ($targetTag.Type -eq 'Package') {
        $targetFolder = $targetTag.Folder.Name
        if ($targetTag.Package.Name -ne $draggedPkg.Name) {
            $beforePkgName = $targetTag.Package.Name
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($targetFolder)) {
        [void](Move-LibraryPackage -PackageName $draggedPkg.Name -TargetFolder $targetFolder -BeforePackageName $beforePkgName)
    }

    $_.Handled = $true
})

$btnSaveToLibrary.Add_Click({
    $pkgName = $txtPkgName.Text.Trim()
    $folderName = Get-SelectedLibraryFolder
    if ([string]::IsNullOrWhiteSpace($pkgName)) {
        [System.Windows.MessageBox]::Show("Please enter a Package Name.", "Validation", "OK", "Warning")
        return
    }
    if ([string]::IsNullOrWhiteSpace($folderName)) {
        $folderName = "General"
        Set-SelectedLibraryFolder "General"
    }
    $targetFolder = Save-PackageToLibraryFolder -PackageName $pkgName -FolderName $folderName -Steps $script:StepsCollection
    $lblStatus.Text = "Saved package '$pkgName' to library under '$($targetFolder.Name)'."
    [System.Windows.MessageBox]::Show("Package '$pkgName' saved successfully to library folder '$($targetFolder.Name)'.", "Saved to Library", "OK", "Information")
})

$btnNewPkg.Add_Click({
    $txtPkgName.Text = "New Deployment Package"
    $sel = $tvLibrary.SelectedItem
    if ($sel -and $sel.Tag -and $sel.Tag.Folder) {
        Set-SelectedLibraryFolder $sel.Tag.Folder.Name
    } else {
        Set-SelectedLibraryFolder "General"
    }
    $script:StepsCollection.Clear()
    Renumber-Steps
    $lblStatus.Text = "Created new empty deployment package. Opening Package Steps Builder..."
    Show-PackageStepsModal
})

if ($btnOpenStepsModal) {
    $btnOpenStepsModal.Add_Click({
        Show-PackageStepsModal
    })
}
if ($menuLibEditSteps) {
    $menuLibEditSteps.Add_Click({
        $sel = $tvLibrary.SelectedItem
        if ($sel -and $sel.Tag -and $sel.Tag.Type -eq 'Package') {
            Load-PackageIntoEditor -Package $sel.Tag.Package -FolderName $sel.Tag.Folder.Name
        }
        Show-PackageStepsModal
    })
}
function Resolve-DeploymentPackageSteps {
    param(
        [string]$PackageName = "",
        $DeployRun = $null
    )
    if ($null -ne $DeployRun -and $DeployRun.PSObject.Properties['PackageSteps'] -and $DeployRun.PackageSteps -and @($DeployRun.PackageSteps).Count -gt 0) {
        return @($DeployRun.PackageSteps)
    }
    $targetName = if (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        $PackageName.Trim()
    } elseif ($null -ne $DeployRun -and $DeployRun.PSObject.Properties['PackageName'] -and -not [string]::IsNullOrWhiteSpace([string]$DeployRun.PackageName)) {
        ([string]$DeployRun.PackageName).Trim()
    } else {
        ""
    }
    if (-not [string]::IsNullOrWhiteSpace($targetName)) {
        if ($script:PackageLibrary) {
            foreach ($folder in $script:PackageLibrary) {
                if (-not $folder.Packages) { continue }
                foreach ($pkg in $folder.Packages) {
                    if ($pkg.Name -ieq $targetName -and $pkg.Steps -and @($pkg.Steps).Count -gt 0) {
                        return @($pkg.Steps)
                    }
                }
            }
        }
        try {
            $catalog = @(Get-CannedScriptsCatalog)
            $cannedMatch = $catalog | Where-Object { $_.Name -ieq $targetName } | Select-Object -First 1
            if ($null -ne $cannedMatch) {
                $stepType = if ($cannedMatch.Type -eq "Batch") { "Batch" } else { "PowerShell" }
                return @(New-StepObject -Name ([string]$cannedMatch.Name).Trim() `
                                        -Type $stepType `
                                        -Script ([string]$cannedMatch.Script) `
                                        -Parameters ([string]$cannedMatch.Parameters).Trim())
            }
        } catch {}
    }
    if ($script:StepsCollection -and $script:StepsCollection.Count -gt 0) {
        return @($script:StepsCollection)
    }
    return @()
}

function Invoke-RedeployDeploymentTask {
    param(
        [Parameter(Mandatory)]$DeployRun,
        [ValidateSet('FailedOnly', 'AllHosts')]
        [string]$Mode = 'AllHosts'
    )
    if ($null -eq $DeployRun) { return }
    $depId   = if ($DeployRun.PSObject.Properties['DeploymentId']) { [string]$DeployRun.DeploymentId } else { "" }
    $pkgName = if ($DeployRun.PSObject.Properties['PackageName'] -and -not [string]::IsNullOrWhiteSpace([string]$DeployRun.PackageName)) {
        ([string]$DeployRun.PackageName).Trim()
    } else {
        "(Custom Package)"
    }

    $matchingRows = @()
    if (-not [string]::IsNullOrWhiteSpace($depId)) {
        $matchingRows = @($script:ResultsCollection | Where-Object { $_.PSObject.Properties['DeploymentId'] -and [string]$_.DeploymentId -eq $depId })
    }
    if ($matchingRows.Count -eq 0 -and -not [string]::IsNullOrWhiteSpace($pkgName)) {
        $matchingRows = @($script:ResultsCollection | Where-Object { $_.PSObject.Properties['PackageName'] -and [string]$_.PackageName -ieq $pkgName })
    }

    $targetHosts = @()
    if ($Mode -eq 'FailedOnly') {
        $targetHosts = @($matchingRows | Where-Object { $_.Status -ne 'Success' } | ForEach-Object { [string]$_.ComputerName } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
        if ($targetHosts.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No failed or incomplete hosts were found for deployment task '$pkgName'.", "Re-deploy to Only Failed Hosts", "OK", "Information")
            return
        }
    } else {
        $fromRows = @($matchingRows | ForEach-Object { [string]$_.ComputerName } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $fromRun  = @()
        if ($DeployRun.PSObject.Properties['TargetComputers'] -and $DeployRun.TargetComputers) {
            $fromRun = @($DeployRun.TargetComputers | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
        $targetHosts = @(@($fromRows) + @($fromRun) | Select-Object -Unique)
        if ($targetHosts.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No target computers were found in deployment task '$pkgName'.", "Re-deploy to All Hosts", "OK", "Warning")
            return
        }
    }

    $resolvedSteps = @(Resolve-DeploymentPackageSteps -PackageName $pkgName -DeployRun $DeployRun)
    if ($resolvedSteps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Could not locate saved package steps for '$pkgName'. Please select the package in the Package Library first.", "Package Steps Not Found", "OK", "Warning")
        return
    }

    Invoke-DeploymentForTargets -TargetComputers $targetHosts -StartStepIndex 0 -PackageName $pkgName -PackageSteps $resolvedSteps
}

if ($dgDeployPackages) {
    $dgDeployPackages.Add_SelectionChanged({
        Invoke-RefreshResultsFilter
    })
    $dgDeployPackages.Add_PreviewMouseRightButtonDown({
        param($sender, $e)
        $depObj = $e.OriginalSource -as [System.Windows.DependencyObject]
        while ($null -ne $depObj -and -not ($depObj -is [System.Windows.Controls.DataGridRow])) {
            if ($depObj -is [System.Windows.Media.Visual] -or $depObj -is [System.Windows.Media.Media3D.Visual3D]) {
                $depObj = [System.Windows.Media.VisualTreeHelper]::GetParent($depObj)
            } else {
                break
            }
        }
        if ($depObj -is [System.Windows.Controls.DataGridRow]) {
            $depObj.IsSelected = $true
            $dgDeployPackages.SelectedItem = $depObj.Item
        }
    })
    $dgDeployPackages.Add_PreviewKeyDown({
        param($sender, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Escape) {
            $dgDeployPackages.SelectedItem = $null
            Invoke-RefreshResultsFilter
            $e.Handled = $true
        }
    })
    $deployCtxMenu = New-Win11ContextMenu

    $miRedeployFailed = New-Win11MenuItem -Header "Re-deploy to Only Failed Hosts" -Glyph "🔄" -ColorHex "#FAB387" -OnClick {
        $selRun = $dgDeployPackages.SelectedItem
        if ($null -eq $selRun) { return }
        Invoke-RedeployDeploymentTask -DeployRun $selRun -Mode 'FailedOnly'
    }
    [void]$deployCtxMenu.Items.Add($miRedeployFailed)

    $miRedeployAll = New-Win11MenuItem -Header "Re-deploy to All Hosts" -Glyph "🚀" -ColorHex "#A6E3A1" -OnClick {
        $selRun = $dgDeployPackages.SelectedItem
        if ($null -eq $selRun) { return }
        Invoke-RedeployDeploymentTask -DeployRun $selRun -Mode 'AllHosts'
    }
    [void]$deployCtxMenu.Items.Add($miRedeployAll)

    [void]$deployCtxMenu.Items.Add((New-Object System.Windows.Controls.Separator))

    $miDeselectDeploy = New-Win11MenuItem -Header "Deselect Deployment Task (Hide Status Log)" -Glyph "👁" -ColorHex "#89B4FA" -OnClick {
        $dgDeployPackages.SelectedItem = $null
        Invoke-RefreshResultsFilter
    }
    [void]$deployCtxMenu.Items.Add($miDeselectDeploy)

    $miRemoveDeployRun = New-Win11MenuItem -Header "Remove Selected Deployment History Entry" -Glyph "🗑" -ColorHex "#F38BA8" -ForegroundHex "#F38BA8" -OnClick {
        $selRun = $dgDeployPackages.SelectedItem
        if ($null -eq $selRun) { return }
        if ($selRun.Status -eq "Running") {
            [System.Windows.MessageBox]::Show("Cannot remove an actively running deployment task. Stop the deployment first.", "Deployment Running", "OK", "Information")
            return
        }
        $depId = [string]$selRun.DeploymentId
        [void]$script:DeployPackagesCollection.Remove($selRun)
        if (-not [string]::IsNullOrWhiteSpace($depId)) {
            $toRem = @($script:ResultsCollection | Where-Object { $_.PSObject.Properties['DeploymentId'] -and [string]$_.DeploymentId -eq $depId })
            foreach ($r in $toRem) {
                [void]$script:ResultsCollection.Remove($r)
            }
        }
        Save-PersistentStatusState
        Invoke-RefreshResultsFilter
    }
    [void]$deployCtxMenu.Items.Add($miRemoveDeployRun)

    $deployCtxMenu.Add_Opened({
        $selRun = $dgDeployPackages.SelectedItem
        $hasSel = ($null -ne $selRun)
        $miRedeployAll.IsEnabled    = $hasSel
        $miDeselectDeploy.IsEnabled = $hasSel
        $miRemoveDeployRun.IsEnabled = ($hasSel -and $selRun.Status -ne "Running")
        if ($hasSel) {
            $depId = if ($selRun.PSObject.Properties['DeploymentId']) { [string]$selRun.DeploymentId } else { "" }
            $failedRows = @($script:ResultsCollection | Where-Object {
                ($_.PSObject.Properties['DeploymentId'] -and [string]$_.DeploymentId -eq $depId) -and $_.Status -ne 'Success'
            })
            $miRedeployFailed.IsEnabled = ($failedRows.Count -gt 0 -or ([int]$selRun.FailedCount -gt 0) -or ([int]$selRun.StoppedCount -gt 0) -or $selRun.Status -in @('Failed', 'Stopped'))
        } else {
            $miRedeployFailed.IsEnabled = $false
        }
    })
    $dgDeployPackages.ContextMenu = $deployCtxMenu
}
if ($btnSelectAllDeployPkgs) {
    $btnSelectAllDeployPkgs.Add_Click({
        if (-not $script:DeployPackagesCollection -or $script:DeployPackagesCollection.Count -eq 0) { return }
        $finishedRuns = @($script:DeployPackagesCollection | Where-Object { $_.Status -ne "Running" })
        if ($finishedRuns.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No completed deployment history entries to clear.", "Clear History", "OK", "Information")
            return
        }
        $ans = [System.Windows.MessageBox]::Show("Clear $($finishedRuns.Count) completed deployment history entry/entries and their status logs?", "Clear Deployment History", "YesNo", "Question")
        if ($ans -ne 'Yes') { return }
        $finishedIds = @{}
        foreach ($fr in $finishedRuns) {
            if ($fr.PSObject.Properties['DeploymentId'] -and -not [string]::IsNullOrWhiteSpace([string]$fr.DeploymentId)) {
                $finishedIds[[string]$fr.DeploymentId] = $true
            }
            [void]$script:DeployPackagesCollection.Remove($fr)
        }
        $rowsToRemove = @($script:ResultsCollection | Where-Object {
            $id = if ($_.PSObject.Properties['DeploymentId']) { [string]$_.DeploymentId } else { "" }
            [string]::IsNullOrWhiteSpace($id) -or $finishedIds.ContainsKey($id)
        })
        foreach ($r in $rowsToRemove) {
            [void]$script:ResultsCollection.Remove($r)
        }
        Save-PersistentStatusState
        if ($dgDeployPackages) { $dgDeployPackages.Items.Refresh() }
        Invoke-RefreshResultsFilter
        $lblStatus.Text = "Cleared $($finishedRuns.Count) deployment history entry/entries."
    })
}
function Show-FolderInputDialog {
    param([string]$Title = "New Library Folder", [string]$Prompt = "Enter folder name:", [string]$DefaultValue = "")
    $escapedTitle  = [System.Security.SecurityElement]::Escape($Title)
    $escapedPrompt = [System.Security.SecurityElement]::Escape($Prompt)
    [xml]$dlgXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$escapedTitle" Width="380" Height="165" WindowStartupLocation="CenterOwner"
        Background="#1E1E2E" Foreground="#CDD6F4" FontFamily="Segoe UI" ResizeMode="NoResize" ShowInTaskbar="False">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="$escapedPrompt" Foreground="#CDD6F4" FontWeight="SemiBold" Margin="0,0,0,8" TextWrapping="Wrap"/>
        <TextBox x:Name="txtInput" Grid.Row="1" Height="28" Background="#313244" Foreground="#CDD6F4" BorderBrush="#45475A" Padding="5,3" Margin="0,0,0,12"/>
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="btnCancel" Content="Cancel" Width="75" Height="26" Background="#45475A" Foreground="#CDD6F4" Margin="0,0,8,0" IsCancel="True"/>
            <Button x:Name="btnOk" Content="OK" Width="75" Height="26" Background="#89B4FA" Foreground="#11111B" FontWeight="Bold" IsDefault="True"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = [System.Xml.XmlNodeReader]::new($dlgXaml)
    $dlg = [System.Windows.Markup.XamlReader]::Load($reader)
    $dlg.Owner = $window
    $txtInput = $dlg.FindName("txtInput")
    if (-not [string]::IsNullOrEmpty($DefaultValue)) {
        $txtInput.Text = $DefaultValue
    }
    $dlg.Add_Loaded({
        $txtInput.Focus()
        $txtInput.SelectAll()
    })
    $btnOk = $dlg.FindName("btnOk")
    $btnOk.Add_Click({ $dlg.DialogResult = $true; $dlg.Close() })
    $res = $dlg.ShowDialog()
    if ($res -eq $true) {
        return $txtInput.Text.Trim()
    }
    return $null
}

function Rename-LibraryFolder {
    param($FolderObj)
    if (-not $FolderObj) { return }
    $oldName = [string]$FolderObj.Name
    if ($oldName -ieq "General") {
        [System.Windows.MessageBox]::Show("The default 'General' folder cannot be renamed.", "Rename Folder", "OK", "Information")
        return
    }
    $newName = Show-FolderInputDialog -Title "Rename Library Folder" -Prompt "Enter new name for folder '$oldName':" -DefaultValue $oldName
    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $oldName) { return }

    $dup = $script:PackageLibrary | Where-Object { $_ -ne $FolderObj -and $_.Name -ieq $newName }
    if ($dup) {
        [System.Windows.MessageBox]::Show("A library folder named '$newName' already exists.", "Folder Exists", "OK", "Warning")
        return
    }

    if (Test-Path $script:PackagesDir) {
        $oldSafeFolder = ($oldName -replace '[\\/:*?"<>|]', '_')
        foreach ($p in $FolderObj.Packages) {
            $safePkgName = ($p.Name -replace '[\\/:*?"<>|]', '_')
            $oldFile = Join-Path $script:PackagesDir "${oldSafeFolder}_${safePkgName}.json"
            if (Test-Path -LiteralPath $oldFile) {
                try { Remove-Item -LiteralPath $oldFile -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
    }

    $wasSelectedFolder = ((Get-SelectedLibraryFolder) -ieq $oldName)
    $FolderObj.Name = $newName
    Save-PackageLibrary
    Refresh-LibraryTreeView
    if ($wasSelectedFolder) {
        Set-SelectedLibraryFolder $newName
    }
    $lblStatus.Text = "Renamed library folder '$oldName' to '$newName'."
}

function Rename-LibraryPackage {
    param($PackageObj, $FolderObj)
    if (-not $PackageObj -or -not $FolderObj) { return }
    $oldName = [string]$PackageObj.Name
    $newName = Show-FolderInputDialog -Title "Rename Deployment Package / Task" -Prompt "Enter new name for package '$oldName':" -DefaultValue $oldName
    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $oldName) { return }

    $dup = $FolderObj.Packages | Where-Object { $_ -ne $PackageObj -and $_.Name -ieq $newName }
    if ($dup) {
        [System.Windows.MessageBox]::Show("A package named '$newName' already exists in folder '$($FolderObj.Name)'.", "Package Exists", "OK", "Warning")
        return
    }

    if (Test-Path $script:PackagesDir) {
        $safeFolder = ($FolderObj.Name -replace '[\\/:*?"<>|]', '_')
        $oldSafePkg = ($oldName -replace '[\\/:*?"<>|]', '_')
        $oldFile = Join-Path $script:PackagesDir "${safeFolder}_${oldSafePkg}.json"
        if (Test-Path -LiteralPath $oldFile) {
            try { Remove-Item -LiteralPath $oldFile -Force -ErrorAction SilentlyContinue } catch {}
        }
    }

    $wasInEditor = ($txtPkgName.Text.Trim() -eq $oldName)
    $PackageObj.Name = $newName
    Save-PackageLibrary
    Refresh-LibraryTreeView -SelectPackageName $newName
    if ($wasInEditor) {
        $txtPkgName.Text = $newName
    }
    $lblStatus.Text = "Renamed package '$oldName' to '$newName'."
}

$createFolderAction = {
    $folderName = Show-FolderInputDialog -Title "New Library Folder" -Prompt "Enter folder name:"
    if ([string]::IsNullOrWhiteSpace($folderName)) { return }

    $existing = $script:PackageLibrary | Where-Object { $_.Name -ieq $folderName } | Select-Object -First 1
    if ($existing) {
        [System.Windows.MessageBox]::Show("A library folder named '$folderName' already exists.", "Folder Exists", "OK", "Warning")
        Set-SelectedLibraryFolder $existing.Name
        return
    }

    $newFolder = Get-OrCreateLibraryFolder -FolderName $folderName
    Save-PackageLibrary
    Refresh-LibraryTreeView
    Set-SelectedLibraryFolder $newFolder.Name
    $lblStatus.Text = "Created library folder '$($newFolder.Name)'."
}

if ($btnNewFolder) {
    $btnNewFolder.Add_Click($createFolderAction)
}
if ($menuLibNewFolder) {
    $menuLibNewFolder.Add_Click($createFolderAction)
}

if ($menuLibSaveHere) {
    $menuLibSaveHere.Add_Click({
        $sel = $tvLibrary.SelectedItem
        if ($sel -and $sel.Tag -and $sel.Tag.Folder) {
            Set-SelectedLibraryFolder $sel.Tag.Folder.Name
        }
        $btnSaveToLibrary.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    })
}

function Invoke-ExportLibraryPackage {
    param(
        $Package = $null,
        [string]$FolderName = ""
    )
    if ($null -ne $Package) {
        Load-PackageIntoEditor -Package $Package -FolderName $FolderName
    } else {
        $sel = $tvLibrary.SelectedItem
        if ($sel -and $sel.Tag -and $sel.Tag.Type -eq 'Package') {
            Load-PackageIntoEditor -Package $sel.Tag.Package -FolderName $sel.Tag.Folder.Name
        }
    }

    if ($script:StepsCollection.Count -eq 0 -and [string]::IsNullOrWhiteSpace($txtPkgName.Text)) {
        [System.Windows.MessageBox]::Show("Please select or right-click a deployment package in the Package Library to export.", "Export Package", "OK", "Information")
        return
    }

    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Package JSON (*.json)|*.json"
    $exportPkgName = if (-not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) { $txtPkgName.Text.Trim() } else { "Deployment_Package" }
    $sfd.FileName = "$($exportPkgName -replace '[\\/:*?"<>| ]', '_').json"
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pkg = [PSCustomObject]@{
            PackageName = $exportPkgName
            Folder      = Get-SelectedLibraryFolder
            Steps       = @($script:StepsCollection | ForEach-Object {
                [PSCustomObject]@{
                    Name          = $_.Name
                    Type          = $_.Type
                    Script        = $_.Script
                    Parameters    = $_.Parameters
                    PayloadPath   = $_.PayloadPath
                    IncludeFolder = $_.IncludeFolder
                    SilentInstall = $_.SilentInstall
                    PauseSeconds  = $_.PauseSeconds
                }
            })
        }
        $pkg | ConvertTo-Json -Depth 5 | Set-Content -Path $sfd.FileName -Encoding UTF8
        $lblStatus.Text = "Package exported to $($sfd.FileName)"
        [System.Windows.MessageBox]::Show("Package exported successfully to:`n$($sfd.FileName)", "Export Package", "OK", "Information")
    }
}

function Invoke-ImportLibraryPackage {
    param([string]$TargetFolderName = "")
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Package JSON (*.json)|*.json"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $rawJson = Get-Content -Path $ofd.FileName -Raw -ErrorAction Stop
            $parsed  = ConvertFrom-Json -InputObject $rawJson -ErrorAction Stop

            $importedPkgName = [System.IO.Path]::GetFileNameWithoutExtension($ofd.FileName)
            $resolvedFolder  = $TargetFolderName
            if ([string]::IsNullOrWhiteSpace($resolvedFolder)) {
                $sel = $tvLibrary.SelectedItem
                if ($sel -and $sel.Tag -and $sel.Tag.Folder) {
                    $resolvedFolder = [string]$sel.Tag.Folder.Name
                }
            }

            $stepsSource = $null
            if ($null -ne $parsed -and $parsed.PSObject.Properties['Steps']) {
                if (-not [string]::IsNullOrWhiteSpace("$($parsed.PackageName)")) {
                    $importedPkgName = "$($parsed.PackageName)".Trim()
                }
                if ([string]::IsNullOrWhiteSpace($resolvedFolder) -and -not [string]::IsNullOrWhiteSpace("$($parsed.Folder)")) {
                    $resolvedFolder = "$($parsed.Folder)".Trim()
                }
                $stepsSource = $parsed.Steps
            } else {
                $stepsSource = $parsed
            }

            if ([string]::IsNullOrWhiteSpace($resolvedFolder)) {
                $resolvedFolder = Get-SelectedLibraryFolder
                if ([string]::IsNullOrWhiteSpace($resolvedFolder)) { $resolvedFolder = "General" }
            }

            # Robust unwrap for PowerShell 5.1 array-wrapping behavior
            $items = @()
            foreach ($entry in $stepsSource) {
                if ($null -ne $entry -and ($entry -is [System.Array] -or $entry -is [System.Collections.IList])) {
                    foreach ($sub in $entry) { if ($null -ne $sub) { $items += $sub } }
                } elseif ($null -ne $entry) {
                    $items += $entry
                }
            }

            $script:StepsCollection.Clear()
            foreach ($p in $items) {
                $type = switch ("$($p.Type)".ToLower()) {
                    "pause"     { "Pause" }
                    "batch"     { "Batch" }
                    "installer" { "Installer" }
                    default     { "PowerShell" }
                }
                $params    = if ($p.Parameters) { "$($p.Parameters)" } else { "" }
                $payload   = if ($p.PayloadPath) { "$($p.PayloadPath)" } else { "" }
                $incFolder = if ($p.IncludeFolder) { [bool]$p.IncludeFolder } else { $false }
                $silent    = if ($null -ne $p.SilentInstall) { [bool]$p.SilentInstall } else { $true }
                $pauseSecs = 0
                if ($p.PauseSeconds -is [System.Array]) {
                    [int]::TryParse("$($p.PauseSeconds[0])", [ref]$pauseSecs) | Out-Null
                } else {
                    [int]::TryParse("$($p.PauseSeconds)", [ref]$pauseSecs) | Out-Null
                }
                $script:StepsCollection.Add((New-StepObject -Name "$($p.Name)" `
                                                            -Type $type `
                                                            -Script "$($p.Script)" `
                                                            -Parameters $params `
                                                            -PayloadPath $payload `
                                                            -IncludeFolder $incFolder `
                                                            -SilentInstall $silent `
                                                            -PauseSeconds $pauseSecs))
            }
            Renumber-Steps
            $txtPkgName.Text = $importedPkgName
            $targetFolder = Save-PackageToLibraryFolder -PackageName $importedPkgName -FolderName $resolvedFolder -Steps $script:StepsCollection
            Set-SelectedLibraryFolder $targetFolder.Name
            $lblStatus.Text = "Imported package '$importedPkgName' ($($items.Count) step(s)) into '$($targetFolder.Name)'."
        } catch {
            [System.Windows.MessageBox]::Show("Import failed: $($_.Exception.Message)", "Import Package", "OK", "Error")
        }
    }
}

if ($menuLibImport) {
    $menuLibImport.Add_Click({
        Invoke-ImportLibraryPackage
    })
}

if ($menuLibExport) {
    $menuLibExport.Add_Click({
        Invoke-ExportLibraryPackage
    })
}

$renameSelectedLibraryNode = {
    $sel = $tvLibrary.SelectedItem
    if (-not $sel -or -not $sel.Tag) {
        [System.Windows.MessageBox]::Show("Please select a folder or deployment package to rename.", "Rename", "OK", "Information")
        return
    }
    if ($sel.Tag.Type -eq 'Folder') {
        Rename-LibraryFolder -FolderObj $sel.Tag.Folder
    } elseif ($sel.Tag.Type -eq 'Package') {
        Rename-LibraryPackage -PackageObj $sel.Tag.Package -FolderObj $sel.Tag.Folder
    }
}

if ($menuLibRename) {
    $menuLibRename.Add_Click($renameSelectedLibraryNode)
}

$tvLibrary.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::F2) {
        & $renameSelectedLibraryNode
        $_.Handled = $true
    }
})

if ($menuLibDelete) {
    $menuLibDelete.Add_Click({
        $btnDeletePkg.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    })
}

$btnDeletePkg.Add_Click({
    $sel = $tvLibrary.SelectedItem
    if (-not $sel -or -not $sel.Tag) {
        [System.Windows.MessageBox]::Show("Please select a package in the library to delete.", "Delete Package", "OK", "Warning")
        return
    }

    if ($sel.Tag.Type -eq 'Package') {
        $pkg = $sel.Tag.Package
        $folder = $sel.Tag.Folder
        $ans = [System.Windows.MessageBox]::Show("Delete package '$($pkg.Name)' from library folder '$($folder.Name)'?", "Confirm Delete", "YesNo", "Question")
        if ($ans -eq 'Yes') {
            [void]$folder.Packages.Remove($pkg)
            Save-PackageLibrary
            Refresh-LibraryTreeView
            $lblStatus.Text = "Deleted package '$($pkg.Name)' from library."
        }
    } elseif ($sel.Tag.Type -eq 'Folder') {
        $folder = $sel.Tag.Folder
        if ($folder.Packages.Count -gt 0) {
            $ans = [System.Windows.MessageBox]::Show("Folder '$($folder.Name)' contains $($folder.Packages.Count) package(s). Delete entire folder and all its packages?", "Confirm Delete Folder", "YesNo", "Warning")
            if ($ans -ne 'Yes') { return }
        }
        [void]$script:PackageLibrary.Remove($folder)
        Save-PackageLibrary
        Refresh-LibraryTreeView
        $lblStatus.Text = "Deleted library folder '$($folder.Name)'."
    }
})
# ==========================================
# 5. TARGET COMPUTERS DISCOVERY ENGINE (BATCHED ASYNC RUNSPACEPOOL + NON-BLOCKING UI DISPATCHERTIMER)
# ==========================================
$script:ProbeRunspacePool      = $null
$script:ActiveProbeJobs        = New-Object System.Collections.ArrayList
$script:PendingProbeQueue      = New-Object System.Collections.Generic.Queue[object]
$script:PendingProbeKeys       = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$script:MaxConcurrentProbes    = 10
$script:ProbeBatchDispatchSize = 5
$script:ProbeTotalQueued       = 0
$script:ProbeCompletedCount    = 0
$script:LastProbeUiRefresh     = [datetime]::MinValue
$script:CurrentProbeCred       = $null
$script:CurrentProbeDomainHint = ""
$script:ProbeDispatcherTimer   = New-Object System.Windows.Threading.DispatcherTimer
$script:ProbeDispatcherTimer.Interval = [TimeSpan]::FromMilliseconds(220)

$script:TargetProbeWorkerScriptBlock = {
    param(
        [string]$CompName,
        [string]$DomainHint = "",
        [System.Management.Automation.PSCredential]$ProbeCred = $null
    )
    $res = @{
        ComputerName = $CompName
        OnlineStatus = "Offline"
        IPAddress    = "N/A"
        CurrentUser  = "Offline"
    }
    if ([string]::IsNullOrWhiteSpace($CompName)) { return $res }
    $cleanName = $CompName.Trim()
    $shortName = ($cleanName -split '\.')[0]

    # Collect active local IPv4 addresses to detect local machine & provide fast local IP
    $localIps = New-Object System.Collections.Generic.List[string]
    try {
        foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ($ni.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $ni.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback) {
                foreach ($ua in $ni.GetIPProperties().UnicastAddresses) {
                    if ($ua.Address -and $ua.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
                        $ipStr = $ua.Address.IPAddressToString
                        if ($ipStr -and -not $ipStr.StartsWith("169.254.")) {
                            [void]$localIps.Add($ipStr)
                        }
                    }
                }
            }
        }
    } catch {}

    $isLocal = ($cleanName -in @('localhost', '127.0.0.1', '::1', '.')) -or
               ($shortName -ieq $env:COMPUTERNAME) -or
               ($shortName -ieq [System.Environment]::MachineName) -or
               ($localIps -contains $cleanName)
    if (-not $isLocal) {
        try {
            $localDns = [System.Net.Dns]::GetHostName()
            if ($cleanName -ieq $localDns -or $shortName -ieq ($localDns -split '\.')[0]) {
                $isLocal = $true
            }
        } catch {}
    }

    if ($isLocal) {
        $res.OnlineStatus = "Online"
        if ($localIps.Count -gt 0) {
            $res.IPAddress = $localIps[0]
        } else {
            try {
                $dnsIps = @([System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) | Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork })
                if ($dnsIps.Count -gt 0) { $res.IPAddress = $dnsIps[0].IPAddressToString } else { $res.IPAddress = "127.0.0.1" }
            } catch {
                $res.IPAddress = "127.0.0.1"
            }
        }
        try {
            $curId = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            if ($curId -and -not [string]::IsNullOrWhiteSpace($curId.Name)) {
                $res.CurrentUser = [string]$curId.Name
            } else {
                $res.CurrentUser = "$env:USERDOMAIN\$env:USERNAME"
            }
        } catch {
            $res.CurrentUser = "$env:USERDOMAIN\$env:USERNAME"
        }
        return $res
    }

    # 1. Resolve IPv4 (array-safe in PS 5.1; try FQDN with DomainHint if bare name fails)
    $candidates = New-Object System.Collections.Generic.List[string]
    [void]$candidates.Add($cleanName)
    if ($cleanName -notmatch '\.' -and $cleanName -notmatch ':') {
        if (-not [string]::IsNullOrWhiteSpace($DomainHint)) {
            [void]$candidates.Add("$cleanName.$($DomainHint.Trim().TrimStart('.'))")
        }
        if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN)) {
            $fqdnEnv = "$cleanName.$($env:USERDNSDOMAIN.Trim())"
            if (-not $candidates.Contains($fqdnEnv)) { [void]$candidates.Add($fqdnEnv) }
        }
    }

    $resolvedTarget = $cleanName
    foreach ($cand in $candidates) {
        try {
            $ips = @([System.Net.Dns]::GetHostAddresses($cand) | Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork })
            if ($ips.Count -gt 0) {
                $res.IPAddress = $ips[0].IPAddressToString
                $resolvedTarget = $cand
                break
            }
        } catch {}
    }

    if ($res.IPAddress -ne "N/A" -and ($localIps -contains $res.IPAddress -or $res.IPAddress -eq "127.0.0.1")) {
        $res.OnlineStatus = "Online"
        try {
            $res.CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        } catch {
            $res.CurrentUser = "$env:USERDOMAIN\$env:USERNAME"
        }
        return $res
    }

    $probeHost = if ($res.IPAddress -ne "N/A") { $res.IPAddress } else { $resolvedTarget }

    # 2. Fast Multi-Vector Reachability Probe (ICMP 2-try -> Parallel TCP 5985/5986/445/135/3389/139/22/80/443 + TCP RST detection)
    $isOnline = $false
    foreach ($pingTarget in @($probeHost, $resolvedTarget) | Select-Object -Unique) {
        if ($isOnline -or [string]::IsNullOrWhiteSpace($pingTarget)) { break }
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            try {
                for ($attempt = 1; $attempt -le 2; $attempt++) {
                    $reply = $ping.Send($pingTarget, 850)
                    if ($reply -and $reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                        $isOnline = $true
                        if ($res.IPAddress -eq "N/A" -and $reply.Address -and $reply.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
                            $res.IPAddress = $reply.Address.IPAddressToString
                        }
                        break
                    }
                }
            } finally {
                $ping.Dispose()
            }
        } catch {}
    }

    # Check management ports in parallel (also serves as reachability probe if ICMP was blocked)
    $portOpen = @{ 5985 = $false; 135 = $false; 445 = $false }
    $portsToCheck = if ($isOnline) { @(5985, 135, 445) } else { @(5985, 5986, 445, 135, 3389, 139, 22, 80, 443) }
    $tcpEntries = New-Object System.Collections.Generic.List[object]
    foreach ($port in $portsToCheck) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $iar = $tcp.BeginConnect($probeHost, $port, $null, $null)
            [void]$tcpEntries.Add([PSCustomObject]@{ Port = $port; Client = $tcp; Async = $iar; Done = $false })
        } catch {}
    }
    $swTcp = [System.Diagnostics.Stopwatch]::StartNew()
    $tcpWaitMs = if ($isOnline) { 550 } else { 950 }
    while ($swTcp.ElapsedMilliseconds -lt $tcpWaitMs) {
        $allDone = $true
        foreach ($entry in $tcpEntries) {
            if ($entry.Done) { continue }
            if ($entry.Async.IsCompleted) {
                $entry.Done = $true
                if ($entry.Client.Connected) {
                    $isOnline = $true
                    if ($portOpen.ContainsKey($entry.Port)) { $portOpen[$entry.Port] = $true }
                } else {
                    try {
                        $entry.Client.EndConnect($entry.Async)
                        if ($entry.Client.Connected) {
                            $isOnline = $true
                            if ($portOpen.ContainsKey($entry.Port)) { $portOpen[$entry.Port] = $true }
                        }
                    } catch [System.Net.Sockets.SocketException] {
                        if ($_.Exception.SocketErrorCode -in @(
                            [System.Net.Sockets.SocketError]::ConnectionRefused,
                            [System.Net.Sockets.SocketError]::AccessDenied
                        )) {
                            $isOnline = $true
                        }
                    } catch {}
                }
            } else {
                $allDone = $false
            }
        }
        if ($allDone -or ($isOnline -and $portOpen[5985])) { break }
        Start-Sleep -Milliseconds 30
    }
    foreach ($entry in $tcpEntries) {
        try { $entry.Client.Close() } catch {}
    }

    if ($isOnline) {
        $res.OnlineStatus = "Online"
        $res.CurrentUser  = "Unknown (Access/Firewall)"

        # Fast-path helper to extract interactive user from an established CIM session
        $resolveSessionUser = {
            param($CimSession)
            $cs = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem -Property UserName -OperationTimeoutSec 4 -ErrorAction Stop
            if ($cs -and -not [string]::IsNullOrWhiteSpace($cs.UserName)) {
                return ([string]$cs.UserName).Trim()
            }
            # Fallback for RDP / secondary / locked interactive sessions where Win32_ComputerSystem.UserName is empty
            try {
                $procs = @(Get-CimInstance -CimSession $CimSession -ClassName Win32_Process -Filter "Name='explorer.exe' OR Name='sihost.exe'" -OperationTimeoutSec 4 -ErrorAction SilentlyContinue)
                foreach ($p in $procs) {
                    $ownerRes = Invoke-CimMethod -CimSession $CimSession -InputObject $p -MethodName GetOwner -OperationTimeoutSec 3 -ErrorAction SilentlyContinue
                    if ($ownerRes -and -not [string]::IsNullOrWhiteSpace($ownerRes.User)) {
                        $u = ([string]$ownerRes.User).Trim()
                        if ($u -notmatch '^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE|UMFD-\d+|DWM-\d+)$') {
                            if (-not [string]::IsNullOrWhiteSpace($ownerRes.Domain)) {
                                return "$($ownerRes.Domain)\$u"
                            }
                            return $u
                        }
                    }
                }
            } catch {}
            return "None (No User Logged On)"
        }

        $hostCandidates = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace($resolvedTarget)) { [void]$hostCandidates.Add($resolvedTarget) }
        if (-not [string]::IsNullOrWhiteSpace($cleanName) -and -not $hostCandidates.Contains($cleanName)) {
            [void]$hostCandidates.Add($cleanName)
        }
        if (-not [string]::IsNullOrWhiteSpace($probeHost) -and -not $hostCandidates.Contains($probeHost)) {
            [void]$hostCandidates.Add($probeHost)
        }

        $resolvedUser = $null

        # 1. Direct WSMan query inside the worker runspace (no nested [powershell]::Create() contention!)
        if ($portOpen[5985] -or (-not $portOpen[135])) {
            foreach ($h in $hostCandidates) {
                if ($null -ne $resolvedUser) { break }
                if ($null -ne $ProbeCred) {
                    for ($try = 1; $try -le 2; $try++) {
                        try {
                            $s = New-CimSession -ComputerName $h -Credential $ProbeCred -OperationTimeoutSec 4 -ErrorAction Stop
                            try {
                                $resolvedUser = (& $resolveSessionUser $s)
                                break
                            } finally {
                                Remove-CimSession -CimSession $s -ErrorAction SilentlyContinue
                            }
                        } catch {
                            if ($try -eq 1 -and $portOpen[5985]) { Start-Sleep -Milliseconds 180 }
                        }
                    }
                    if ($null -ne $resolvedUser) { break }
                }
                try {
                    $s = New-CimSession -ComputerName $h -OperationTimeoutSec 3 -ErrorAction Stop
                    try {
                        $resolvedUser = (& $resolveSessionUser $s)
                        break
                    } finally {
                        Remove-CimSession -CimSession $s -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        }

        # 2. DCOM fallback only if WSMan did not succeed AND RPC port 135 is open
        if ($null -eq $resolvedUser -and $portOpen[135]) {
            $dcomOpt = New-CimSessionOption -Protocol Dcom
            foreach ($h in $hostCandidates) {
                if ($null -ne $resolvedUser) { break }
                if ($null -ne $ProbeCred) {
                    try {
                        $s = New-CimSession -ComputerName $h -Credential $ProbeCred -SessionOption $dcomOpt -OperationTimeoutSec 3 -ErrorAction Stop
                        try {
                            $resolvedUser = (& $resolveSessionUser $s)
                            break
                        } finally {
                            Remove-CimSession -CimSession $s -ErrorAction SilentlyContinue
                        }
                    } catch {}
                }
                try {
                    $s = New-CimSession -ComputerName $h -SessionOption $dcomOpt -OperationTimeoutSec 3 -ErrorAction Stop
                    try {
                        $resolvedUser = (& $resolveSessionUser $s)
                        break
                    } finally {
                        Remove-CimSession -CimSession $s -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($resolvedUser)) {
            $res.CurrentUser = $resolvedUser
        }
    } else {
        $res.OnlineStatus = "Offline"
        $res.CurrentUser  = "Offline"
    }
    return $res
}

$script:ProbeDispatcherTimer.Add_Tick({
    # 1. Harvest completed or timed-out active probe jobs
    $anyCompleted = $false
    $now = [datetime]::Now

    for ($idx = $script:ActiveProbeJobs.Count - 1; $idx -ge 0; $idx--) {
        $job = $script:ActiveProbeJobs[$idx]
        $elapsedSec = ($now - $job.StartedAt).TotalSeconds
        $isDone = $job.Handle.IsCompleted
        $isTimeout = (-not $isDone) -and ($elapsedSec -gt 18.0)

        if ($isDone -or $isTimeout) {
            $targetItem = $job.TargetItem
            $key = if ($targetItem -and $targetItem.ComputerName) { $targetItem.ComputerName.Trim() } else { "" }
            if ($key) { [void]$script:PendingProbeKeys.Remove($key) }

            if ($isDone) {
                try {
                    $out = $job.PowerShell.EndInvoke($job.Handle)
                    $r = if ($out -and $out.Count -gt 0) { $out[0] } else { $null }
                    if ($r -and $targetItem) {
                        $targetItem.OnlineStatus = "$($r.OnlineStatus)"
                        $targetItem.IPAddress    = "$($r.IPAddress)"
                        $newUser = "$($r.CurrentUser)"
                        # Preserve last known Domain\User if host is online on VPN/firewall where WinRM/RPC ports are closed
                        if ($newUser -eq "Unknown (Access/Firewall)" -and
                            -not [string]::IsNullOrWhiteSpace($job.PreviousUser) -and
                            $job.PreviousUser -notin @("Unknown", "Offline", "...", "Probing...", "Unknown (Access/Firewall)")) {
                            $targetItem.LogonUser = $job.PreviousUser
                        } else {
                            $targetItem.LogonUser = $newUser
                        }
                        if ($null -ne $targetItem.PSObject.Properties['CurrentUser']) {
                            $targetItem.CurrentUser = $targetItem.LogonUser
                        }
                    }
                } catch {
                    if ($targetItem) {
                        $targetItem.OnlineStatus = "Offline"
                        $targetItem.IPAddress    = "N/A"
                        $targetItem.LogonUser    = "Offline"
                        if ($null -ne $targetItem.PSObject.Properties['CurrentUser']) {
                            $targetItem.CurrentUser = "Offline"
                        }
                    }
                }
            } else {
                if ($targetItem) {
                    $targetItem.OnlineStatus = "Offline"
                    if ($targetItem.IPAddress -in @("...", "Resolving...")) {
                        $targetItem.IPAddress = "N/A"
                    }
                    $targetItem.LogonUser = "Offline"
                    if ($null -ne $targetItem.PSObject.Properties['CurrentUser']) {
                        $targetItem.CurrentUser = "Offline"
                    }
                }
            }

            try { $job.PowerShell.Dispose() } catch {}
            $script:ActiveProbeJobs.RemoveAt($idx)
            $script:ProbeCompletedCount++
            $anyCompleted = $true
        }
    }

    # 2. Dispatch next small batch of queued targets up to $script:MaxConcurrentProbes (non-blocking)
    $dispatchedThisTick = 0
    while ($script:ActiveProbeJobs.Count -lt $script:MaxConcurrentProbes -and
           $script:PendingProbeQueue.Count -gt 0 -and
           $dispatchedThisTick -lt $script:ProbeBatchDispatchSize) {
        $t = $script:PendingProbeQueue.Dequeue()
        if (-not $t -or [string]::IsNullOrWhiteSpace($t.ComputerName)) { continue }

        $prevUser = if ($t.LogonUser) { "$($t.LogonUser)" } else { "" }
        $t.OnlineStatus = "Probing..."

        $domHint = $script:CurrentProbeDomainHint
        if ($t.OUPath -and $t.OUPath -match '^([A-Za-z0-9.-]+\.[A-Za-z]{2,})/') {
            $domHint = $matches[1]
        }

        $ps = [powershell]::Create()
        $ps.RunspacePool = $script:ProbeRunspacePool
        [void]$ps.AddScript($script:TargetProbeWorkerScriptBlock).AddArgument($t.ComputerName).AddArgument($domHint).AddArgument($script:CurrentProbeCred)
        $handle = $ps.BeginInvoke()

        [void]$script:ActiveProbeJobs.Add([PSCustomObject]@{
            TargetItem   = $t
            PowerShell   = $ps
            Handle       = $handle
            StartedAt    = [datetime]::Now
            PreviousUser = $prevUser
        })
        $dispatchedThisTick++
    }

    $allFinished = ($script:ActiveProbeJobs.Count -eq 0 -and $script:PendingProbeQueue.Count -eq 0)

    # 3. Throttled, interaction-safe UI refresh (never freeze scrolling, clicking, or typing)
    if ($anyCompleted -or $allFinished) {
        Update-TargetCountSummary
        $msSinceRefresh = ($now - $script:LastProbeUiRefresh).TotalMilliseconds
        $mouseBusy = ([System.Windows.Input.Mouse]::LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed) -or
                     ([System.Windows.Input.Mouse]::RightButton -eq [System.Windows.Input.MouseButtonState]::Pressed)

        if ($allFinished -or ($msSinceRefresh -ge 1000 -and -not $mouseBusy)) {
            try { $dgTargets.Items.Refresh() } catch {}
            $script:LastProbeUiRefresh = $now
        }

        if (-not $allFinished) {
            $lblStatus.Text = "Probing targets in background ($($script:ActiveProbeJobs.Count) active)... ($script:ProbeCompletedCount / $script:ProbeTotalQueued completed)"
        }
    }

    if ($allFinished) {
        $script:ProbeDispatcherTimer.Stop()
        $script:PendingProbeKeys.Clear()
        try { $dgTargets.Items.Refresh() } catch {}
        Update-TargetCountSummary
        Save-ComputerInventory
        $onlineCount = @($script:TargetsCollection | Where-Object { $_.OnlineStatus -eq 'Online' }).Count
        $offlineCount = @($script:TargetsCollection | Where-Object { $_.OnlineStatus -eq 'Offline' }).Count
        $lblStatus.Text = "Target status probe complete: $onlineCount Online, $offlineCount Offline (of $($script:TargetsCollection.Count) total)."
        Write-DiagnosticLog "Target status probe complete: $onlineCount Online, $offlineCount Offline (of $($script:TargetsCollection.Count) total)."
    }
})

function Get-ConfiguredProbeCredential {
    try {
        if ($null -ne $script:AppSettings -and
            -not [string]::IsNullOrWhiteSpace($script:AppSettings.Username) -and
            $null -ne $script:AppSettings.SecurePassword -and
            $script:AppSettings.SecurePassword.Length -gt 0) {
            $usr = $script:AppSettings.Username.Trim()
            if (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Domain) -and $usr -notmatch '\\' -and $usr -notmatch '@') {
                $usr = "$($script:AppSettings.Domain.Trim())\$usr"
            }
            return (New-Object System.Management.Automation.PSCredential($usr, $script:AppSettings.SecurePassword))
        }
    } catch {}
    return $null
}

function Start-BackgroundTargetProbe {
    param([Parameter(Mandatory=$false)][object[]]$TargetsToProbe)

    if (-not $TargetsToProbe -or $TargetsToProbe.Count -eq 0) {
        $TargetsToProbe = @($script:TargetsCollection)
    }
    if (-not $TargetsToProbe -or $TargetsToProbe.Count -eq 0) { return }

    if ($null -eq $script:ProbeRunspacePool -or $script:ProbeRunspacePool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
        $script:ProbeRunspacePool = [runspacefactory]::CreateRunspacePool(1, 12)
        $script:ProbeRunspacePool.Open()
    }

    if ($script:ActiveProbeJobs.Count -eq 0 -and $script:PendingProbeQueue.Count -eq 0) {
        $script:ProbeTotalQueued    = 0
        $script:ProbeCompletedCount = 0
        $script:PendingProbeKeys.Clear()
    }

    if ($txtAdDomain -and -not [string]::IsNullOrWhiteSpace($txtAdDomain.Text)) {
        $script:CurrentProbeDomainHint = $txtAdDomain.Text.Trim()
    } elseif (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Domain)) {
        $script:CurrentProbeDomainHint = $script:AppSettings.Domain.Trim()
    } else {
        $script:CurrentProbeDomainHint = ""
    }

    $script:CurrentProbeCred = Get-ConfiguredProbeCredential

    $queuedNow = 0
    foreach ($t in $TargetsToProbe) {
        if (-not $t -or [string]::IsNullOrWhiteSpace($t.ComputerName)) { continue }
        $key = $t.ComputerName.Trim()
        if (-not $script:PendingProbeKeys.Add($key)) { continue }

        $script:PendingProbeQueue.Enqueue($t)
        $script:ProbeTotalQueued++
        $queuedNow++
    }

    if ($queuedNow -gt 0) {
        $lblStatus.Text = "Queued $queuedNow target(s) for background batch probing... ($script:ProbeCompletedCount / $script:ProbeTotalQueued completed)"
        if (-not $script:ProbeDispatcherTimer.IsEnabled) {
            $script:ProbeDispatcherTimer.Start()
        }
    }
}

$script:AutoProbeTimer = $null

function Update-AutoProbeTimer {
    if ($null -ne $script:AutoProbeTimer) {
        $script:AutoProbeTimer.Stop()
        $script:AutoProbeTimer = $null
    }
    $probeOn = if ($null -ne $script:AppSettings -and $null -ne $script:AppSettings.AutoProbeInventory) {
        [bool]$script:AppSettings.AutoProbeInventory
    } else {
        $true
    }
    if (-not $probeOn) { return }

    $mins = if ($null -ne $script:AppSettings -and $script:AppSettings.AutoProbeIntervalMinutes) {
        [Math]::Min(240, [Math]::Max(1, [int]$script:AppSettings.AutoProbeIntervalMinutes))
    } else {
        15
    }
    $script:AutoProbeTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:AutoProbeTimer.Interval = [TimeSpan]::FromMinutes($mins)
    $script:AutoProbeTimer.Add_Tick({
        if (-not $script:AppIsClosing -and
            $null -ne $script:TargetsCollection -and
            $script:TargetsCollection.Count -gt 0 -and
            $script:ActiveProbeJobs.Count -eq 0 -and
            $script:PendingProbeQueue.Count -eq 0) {
            Start-BackgroundTargetProbe -TargetsToProbe @($script:TargetsCollection)
        }
    })
    $script:AutoProbeTimer.Start()
}

function Update-TargetLiveStatus {
    param([Alias("TargetItem")]$Target)
    if (-not $Target) { return }
    Start-BackgroundTargetProbe -TargetsToProbe @($Target)
}

function Save-ComputerInventory {
    try {
        if (-not $script:InventoryFilePath) { return }
        $items = @($script:TargetsCollection | Where-Object {
            $_ -and -not [string]::IsNullOrWhiteSpace("$($_.ComputerName)") -and ("$($_.ComputerName)".Trim() -notmatch '\s+')
        } | ForEach-Object {
            [ordered]@{
                Selected          = [bool]$_.Selected
                ComputerName      = "$($_.ComputerName)".Trim()
                OnlineStatus      = if ($_.OnlineStatus -and $_.OnlineStatus -ne "Probing...") { "$($_.OnlineStatus)" } else { "Unknown" }
                IPAddress         = if ($_.IPAddress -and $_.IPAddress -ne "...") { "$($_.IPAddress)" } else { "" }
                LogonUser         = if ($_.LogonUser -and $_.LogonUser -ne "...") { "$($_.LogonUser)" } else { "" }
                OUPath            = if ($null -ne $_.PSObject.Properties['OUPath'] -and $_.OUPath) { "$($_.OUPath)" } else { "Manual / Workgroup" }
                ADLastLogon       = if ($null -ne $_.PSObject.Properties['ADLastLogon'] -and $_.ADLastLogon) { "$($_.ADLastLogon)" } else { "N/A" }
                DistinguishedName = if ($null -ne $_.PSObject.Properties['DistinguishedName'] -and $_.DistinguishedName) { "$($_.DistinguishedName)" } else { "" }
                Source            = if ($null -ne $_.PSObject.Properties['Source'] -and $_.Source) { "$($_.Source)" } else { "Manual" }
            }
        })
        if ($items.Count -eq 0) {
            [System.IO.File]::WriteAllText($script:InventoryFilePath, "[]", [System.Text.Encoding]::UTF8)
        } else {
            $json = ConvertTo-Json -InputObject @($items) -Depth 4
            if (-not $json.TrimStart().StartsWith("[")) {
                $json = "[`r`n$json`r`n]"
            }
            [System.IO.File]::WriteAllText($script:InventoryFilePath, $json, [System.Text.Encoding]::UTF8)
        }
    } catch {
        Write-DiagnosticLog "Failed to save computer inventory: $($_.Exception.Message)" "WARN"
    }
}

$script:InventoryNeedsAdResync = $false

function Load-ComputerInventory {
    if (-not $script:InventoryFilePath -or -not (Test-Path -LiteralPath $script:InventoryFilePath)) { return }
    try {
        $raw = [System.IO.File]::ReadAllText($script:InventoryFilePath, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return }
        $parsed = ConvertFrom-Json -InputObject $raw
        if ($null -eq $parsed) { return }

        # Unwrap nested arrays safely across both Windows PowerShell 5.1 (ps2exe) and PowerShell 7
        $loaded = [System.Collections.Generic.List[object]]::new()
        foreach ($entry in $parsed) {
            if ($null -eq $entry) { continue }
            if ($entry -is [System.Array] -or $entry -is [System.Collections.IList]) {
                foreach ($sub in $entry) {
                    if ($null -ne $sub) { $loaded.Add($sub) }
                }
            } else {
                $loaded.Add($entry)
            }
        }
        if ($loaded.Count -eq 0) { return }

        $seenHosts = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        $repairedCorruptedRow = $false
        $repairedSplitNames = [System.Collections.Generic.List[string]]::new()

        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dgTargets.ItemsSource)
        $defer = if ($null -ne $view) { $view.DeferRefresh() } else { $null }
        try {
            $script:TargetsCollection.Clear()

            # Pass 1: Load all valid single-hostname computer items in O(1) per row
            foreach ($item in $loaded) {
                if (-not $item -or [string]::IsNullOrWhiteSpace("$($item.ComputerName)")) { continue }
                $cName = "$($item.ComputerName)".Trim()
                if ($cName -match '\s+') {
                    $repairedCorruptedRow = $true
                    foreach ($part in ($cName -split '\s+')) {
                        $cleanPart = $part.Trim()
                        if (-not [string]::IsNullOrWhiteSpace($cleanPart)) {
                            $repairedSplitNames.Add($cleanPart)
                        }
                    }
                    continue
                }
                if (-not $seenHosts.Add($cName)) { continue }
                $ouVal = if ($null -ne $item.PSObject.Properties['OUPath'] -and -not [string]::IsNullOrWhiteSpace("$($item.OUPath)")) { "$($item.OUPath)" } else { "Manual / Workgroup" }
                $llVal = if ($null -ne $item.PSObject.Properties['ADLastLogon'] -and -not [string]::IsNullOrWhiteSpace("$($item.ADLastLogon)")) { "$($item.ADLastLogon)" } else { "N/A" }
                $dnVal = if ($null -ne $item.PSObject.Properties['DistinguishedName']) { "$($item.DistinguishedName)" } else { "" }
                $srcVal = if ($null -ne $item.PSObject.Properties['Source'] -and -not [string]::IsNullOrWhiteSpace("$($item.Source)")) { "$($item.Source)" } else { "Manual" }
                $tObj = [PSCustomObject]@{
                    Selected          = if ($null -ne $item.PSObject.Properties['Selected']) { [bool]$item.Selected } else { $false }
                    ComputerName      = $cName
                    OnlineStatus      = if ($item.OnlineStatus) { "$($item.OnlineStatus)" } else { "Unknown" }
                    IPAddress         = if ($item.IPAddress) { "$($item.IPAddress)" } else { "" }
                    LogonUser         = if ($item.LogonUser) { "$($item.LogonUser)" } else { "" }
                    CurrentUser       = if ($item.LogonUser) { "$($item.LogonUser)" } else { "" }
                    OUPath            = $ouVal
                    ADLastLogon       = $llVal
                    DistinguishedName = $dnVal
                    Source            = $srcVal
                }
                $script:TargetsCollection.Add($tObj)
            }

            # Pass 2: If a corrupted space-combined row existed, recover any hostnames not already present
            if ($repairedSplitNames.Count -gt 0) {
                foreach ($splitHost in $repairedSplitNames) {
                    if ($seenHosts.Add($splitHost)) {
                        $script:InventoryNeedsAdResync = $true
                        $script:TargetsCollection.Add([PSCustomObject]@{
                            Selected          = $false
                            ComputerName      = $splitHost
                            OnlineStatus      = "Unknown"
                            IPAddress         = ""
                            LogonUser         = ""
                            CurrentUser       = ""
                            OUPath            = "Manual / Workgroup"
                            ADLastLogon       = "N/A"
                            DistinguishedName = ""
                            Source            = "ADSync"
                        })
                    }
                }
            }
        } finally {
            if ($null -ne $defer) {
                try { $defer.Dispose() } catch {}
            }
        }

        if ($repairedCorruptedRow) {
            Save-ComputerInventory
        }

        Update-TargetCountSummary
        $autoProbeOnStartup = if ($null -ne $script:AppSettings -and $null -ne $script:AppSettings.AutoProbeInventory) {
            [bool]$script:AppSettings.AutoProbeInventory
        } else {
            $true
        }
        if ($script:TargetsCollection.Count -gt 0 -and $autoProbeOnStartup) {
            Start-BackgroundTargetProbe -TargetsToProbe @($script:TargetsCollection)
        }
    } catch {
        Write-DiagnosticLog "Failed to load computer inventory: $($_.Exception.Message)" "WARN"
    }
}

function Add-TargetComputers {
    param(
        [Alias("RawList", "ComputerNames")][string[]]$Hostnames,
        [object[]]$ComputerItems,
        [string]$DefaultSource = "Manual",
        [switch]$SkipSave
    )
    $addedItems = New-Object System.Collections.Generic.List[PSCustomObject]

    $normalizedInput = New-Object System.Collections.Generic.List[PSCustomObject]
    if ($ComputerItems -and $ComputerItems.Count -gt 0) {
        foreach ($ci in $ComputerItems) {
            if ($null -eq $ci) { continue }
            if ($ci -is [string]) {
                $normalizedInput.Add([PSCustomObject]@{
                    ComputerName      = $ci
                    OUPath            = "Manual / Workgroup"
                    ADLastLogon       = "N/A"
                    DistinguishedName = ""
                    Source            = $DefaultSource
                })
            } else {
                $cNameProp = if ($ci.PSObject.Properties['ComputerName'] -and $ci.ComputerName) { "$($ci.ComputerName)" }
                             elseif ($ci.PSObject.Properties['Name'] -and $ci.Name) { "$($ci.Name)" }
                             else { "" }
                $normalizedInput.Add([PSCustomObject]@{
                    ComputerName      = $cNameProp
                    OUPath            = if ($ci.PSObject.Properties['OUPath'] -and $ci.OUPath) { "$($ci.OUPath)" } else { "Manual / Workgroup" }
                    ADLastLogon       = if ($ci.PSObject.Properties['ADLastLogon'] -and $ci.ADLastLogon) { "$($ci.ADLastLogon)" } else { "N/A" }
                    DistinguishedName = if ($ci.PSObject.Properties['DistinguishedName'] -and $ci.DistinguishedName) { "$($ci.DistinguishedName)" } else { "" }
                    Source            = if ($ci.PSObject.Properties['Source'] -and $ci.Source) { "$($ci.Source)" } else { $DefaultSource }
                })
            }
        }
    } elseif ($Hostnames -and $Hostnames.Count -gt 0) {
        foreach ($raw in $Hostnames) {
            $normalizedInput.Add([PSCustomObject]@{
                ComputerName      = "$raw"
                OUPath            = "Manual / Workgroup"
                ADLastLogon       = "N/A"
                DistinguishedName = ""
                Source            = $DefaultSource
            })
        }
    } else {
        return
    }

    foreach ($entry in $normalizedInput) {
        $clean = "$($entry.ComputerName)".Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) { continue }

        $exists = $script:TargetsCollection | Where-Object { $_.ComputerName -ieq $clean }
        if (-not $exists) {
            $targetObj = [PSCustomObject]@{
                Selected          = $false
                ComputerName      = $clean
                OnlineStatus      = "Probing..."
                IPAddress         = "..."
                LogonUser         = "..."
                CurrentUser       = "..."
                OUPath            = "$($entry.OUPath)"
                ADLastLogon       = "$($entry.ADLastLogon)"
                DistinguishedName = "$($entry.DistinguishedName)"
                Source            = "$($entry.Source)"
            }
            $script:TargetsCollection.Add($targetObj)
            $addedItems.Add($targetObj)
        } else {
            if ($entry.OUPath -and $entry.OUPath -ne "Manual / Workgroup") {
                $exists.OUPath = "$($entry.OUPath)"
            }
            if ($entry.ADLastLogon -and $entry.ADLastLogon -ne "N/A") {
                $exists.ADLastLogon = "$($entry.ADLastLogon)"
            }
            if ($entry.DistinguishedName) {
                $exists.DistinguishedName = "$($entry.DistinguishedName)"
            }
            if ($entry.Source -and $entry.Source -ne "Manual") {
                $exists.Source = "$($entry.Source)"
            }
        }
    }

    Update-TargetCountSummary
    if (-not $SkipSave) {
        Save-ComputerInventory
    }
    if ($addedItems.Count -gt 0) {
        Write-DiagnosticLog "Queued $($addedItems.Count) new computer(s) in Computer Inventory for background probe."
        Start-BackgroundTargetProbe -TargetsToProbe $addedItems.ToArray()
    }
}

$btnAddTargets.Add_Click({
    $rawInput = $txtSingleComp.Text
    if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
        $hosts = $rawInput -split '[,;\r\n\s]+' | Where-Object { $_ }
        Add-TargetComputers -Hostnames $hosts
        $txtSingleComp.Text = ""
    } else {
        [System.Windows.MessageBox]::Show("Enter one or more computer names (comma, space, or newline separated).", "Add Targets", "OK", "Information")
    }
})

if ($btnBrowseCSV) { $btnBrowseCSV.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
    $ofd.Title = "Import Computers from CSV"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $csvData = @(Import-Csv -Path $ofd.FileName -ErrorAction Stop)
            if ($csvData.Count -gt 0) {
                $col = if ($csvData[0].PSObject.Properties.Name -contains 'ComputerName') {
                    'ComputerName'
                } else {
                    ($csvData[0].PSObject.Properties | Select-Object -First 1).Name
                }
                $hosts = @($csvData | ForEach-Object { "$($_.$col)".Trim() } | Where-Object { $_ })
                Add-TargetComputers -Hostnames $hosts
            }
        } catch {
            [System.Windows.MessageBox]::Show("Failed to read CSV: $($_.Exception.Message)", "CSV Error", "OK", "Error")
        }
    }
}) }

# ==========================================
# 5B. ACTIVE DIRECTORY OU & COMPUTER BROWSER
# ==========================================
function Get-DefaultAdDomainName {
    if ($script:AppSettings -and -not [string]::IsNullOrWhiteSpace($script:AppSettings.Domain)) {
        $cfgDom = $script:AppSettings.Domain.Trim()
        if ($cfgDom -notmatch '^(localhost|127\.0\.0\.1|\.)$') {
            return $cfgDom
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN)) {
        return $env:USERDNSDOMAIN.Trim()
    }
    try {
        $curDom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        if ($curDom -and -not [string]::IsNullOrWhiteSpace($curDom.Name)) {
            return $curDom.Name
        }
    } catch {}
    return ""
}

function New-AdDirectoryEntry {
    param([string]$LdapPath)

    $useCurrent = $true
    if ($script:AppSettings) {
        if ($null -ne $script:AppSettings.PSObject.Properties['UseCurrentLogon']) {
            $useCurrent = [bool]$script:AppSettings.UseCurrentLogon
        } elseif ($null -ne $script:AppSettings.PSObject.Properties['UseCurrentCred']) {
            $useCurrent = [bool]$script:AppSettings.UseCurrentCred
        }
    }

    $secPass = $null
    if ($null -ne $script:SavedSecurePassword) {
        $secPass = $script:SavedSecurePassword
    } elseif ($script:AppSettings -and $null -ne $script:AppSettings.SecurePassword) {
        $secPass = $script:AppSettings.SecurePassword
    }

    if ((-not $useCurrent) -and $script:AppSettings -and (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Username)) -and ($null -ne $secPass) -and ($secPass.Length -gt 0)) {
        $bstr = [IntPtr]::Zero
        try {
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPass)
            $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            $userRaw = $script:AppSettings.Username.Trim()
            $domRaw  = if ($script:AppSettings.Domain) { $script:AppSettings.Domain.Trim() } else { "" }
            $adUser  = if ($userRaw -match '[\\@]' -or [string]::IsNullOrWhiteSpace($domRaw) -or $domRaw -match '^(localhost|127\.0\.0\.1|\.)$') {
                $userRaw
            } else {
                "$domRaw\$userRaw"
            }
            return (New-Object System.DirectoryServices.DirectoryEntry($LdapPath, $adUser, $plainPass, [System.DirectoryServices.AuthenticationTypes]::Secure))
        } finally {
            if ($bstr -ne [IntPtr]::Zero) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
    }

    return (New-Object System.DirectoryServices.DirectoryEntry($LdapPath))
}

function ConvertFrom-DistinguishedNameToCanonical {
    param(
        [string]$DistinguishedName,
        [switch]$IsContainerDN
    )
    if ([string]::IsNullOrWhiteSpace($DistinguishedName)) { return "" }
    $parts = @($DistinguishedName -split '(?<!\\),')
    $dcs = New-Object System.Collections.Generic.List[string]
    $containers = New-Object System.Collections.Generic.List[string]
    $startIndex = if ($IsContainerDN) { 0 } else { 1 }
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $p = $parts[$i].Trim()
        if ($p -match '^(?i)DC=(.+)$') {
            $dcs.Add($Matches[1])
        } elseif ($i -ge $startIndex -and $p -match '^(?i)(?:OU|CN)=(.+)$') {
            $containers.Add($Matches[1])
        }
    }
    $containers.Reverse()
    $domainPart = ($dcs -join '.').ToUpperInvariant()
    if ($containers.Count -gt 0) {
        return "$domainPart/$($containers -join '/')"
    }
    return $domainPart
}

function ConvertFrom-AdFileTime {
    param($RawValue)
    if ($null -eq $RawValue) { return "Never" }
    try {
        $ft = [int64]$RawValue
        if ($ft -le 0) { return "Never" }
        $dt = [DateTime]::FromFileTime($ft)
        if ($dt.Year -le 1601) { return "Never" }
        return $dt.ToString("yyyy-MM-dd HH:mm")
    } catch {
        return "Never"
    }
}

function Show-ActiveDirectoryImportDialog {
    [xml]$adBrowserXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Import Computers from Active Directory"
        Width="980" Height="640" MinWidth="820" MinHeight="500"
        ResizeMode="CanResizeWithGrip"
        WindowStartupLocation="CenterOwner"
        Background="#1E1E2E" Foreground="#CDD6F4" FontFamily="Segoe UI" FontSize="12.5">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#89B4FA"/>
            <Setter Property="Foreground" Value="#11111B"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="10,4"/>
            <Setter Property="Margin" Value="3"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.88"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#6C7086"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="CaretBrush" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <ControlTemplate x:Key="ComboBoxToggleButtonTemplate" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="26"/>
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" CornerRadius="4"
                        Background="#313244" BorderBrush="#45475A" BorderThickness="1"/>
                <Path Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center"
                      Data="M 0 0 L 4 4 L 8 0 Z" Fill="#CDD6F4"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Border" Property="BorderBrush" Value="#89B4FA"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,3"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton"
                                          Template="{StaticResource ComboBoxToggleButtonTemplate}"
                                          Focusable="False"
                                          IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                          ClickMode="Press"/>
                            <ContentPresenter Name="ContentSite"
                                              IsHitTestVisible="False"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="8,3,28,3"
                                              VerticalAlignment="Center"
                                              HorizontalAlignment="Left"/>
                            <Popup Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True"
                                   Focusable="False"
                                   PopupAnimation="Slide">
                                <Grid Name="DropDown"
                                      SnapsToDevicePixels="True"
                                      MinWidth="{TemplateBinding ActualWidth}"
                                      MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <Border x:Name="DropDownBorder"
                                            Background="#181825"
                                            BorderThickness="1"
                                            BorderBrush="#89B4FA"
                                            CornerRadius="4"/>
                                    <ScrollViewer Margin="2" SnapsToDevicePixels="True">
                                        <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#313244"/>
                    <Setter Property="Foreground" Value="#89B4FA"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#A6E3A1"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="TreeView">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <Style TargetType="TreeViewItem">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="Padding" Value="4,2"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#89B4FA"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="RowBackground" Value="#1E1E2E"/>
            <Setter Property="AlternatingRowBackground" Value="#262637"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#313244"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
            <Setter Property="RowHeaderWidth" Value="0"/>
        </Style>

        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#89B4FA"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>

        <Style TargetType="DataGridRow">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="DataGridCell">
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridCell">
                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#45475A"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- TOP BAR: AD DOMAIN / LDAP SERVER CONNECTION -->
        <Border Grid.Row="0" Background="#181825" CornerRadius="6" Padding="10" Margin="0,0,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="250"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="🌐 Domain / LDAP Server:" FontWeight="Bold" Foreground="#89DCEB" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBox x:Name="txtAdDomain" Grid.Column="1" Height="28" Margin="0,0,8,0"
                         ToolTip="Enter Active Directory domain FQDN (e.g. corp.contoso.com), Domain Controller hostname, or leave blank for current domain"/>
                <Button x:Name="btnAdConnect" Grid.Column="2" Content="🔗 Connect / Load OUs" Width="Auto" Height="28" Padding="12,2"
                        Background="#89B4FA" Foreground="#11111B" Margin="0,0,10,0"
                        ToolTip="Bind to Active Directory RootDSE and load Organizational Units"/>
                <TextBlock x:Name="lblAdConnStatus" Grid.Column="3" Text="Not connected." Foreground="#A6ADC8" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
            </Grid>
        </Border>

        <!-- MIDDLE SPLIT WORKSPACE: LEFT OU TREE + VERTICAL SPLITTER + RIGHT COMPUTERS GRID -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition x:Name="colAdOuTree" Width="310" MinWidth="220"/>
                <ColumnDefinition Width="6"/>
                <ColumnDefinition Width="*" MinWidth="450"/>
            </Grid.ColumnDefinitions>

            <!-- LEFT PANE: ORGANIZATIONAL UNITS & CONTAINERS -->
            <Border Grid.Column="0" Background="#181825" CornerRadius="6" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="📂 ACTIVE DIRECTORY CONTAINERS &amp; OUs" FontWeight="Bold" Foreground="#F9E2AF" Margin="0,0,0,6"/>
                    <CheckBox x:Name="chkAdIncludeSubOUs" Grid.Row="1" Content="Include sub-OUs when loading computers"
                              IsChecked="True" Foreground="#A6E3A1" FontWeight="SemiBold" Margin="0,0,0,8"
                              ToolTip="When checked, selecting an OU loads computers in that OU and all nested child OUs (Subtree search)"/>
                    <TreeView x:Name="tvAdOUs" Grid.Row="2"
                              ToolTip="Select the domain root, an Organizational Unit (OU), or a container to view computers"/>
                </Grid>
            </Border>

            <!-- VERTICAL SPLITTER -->
            <GridSplitter Grid.Column="1" Width="6" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                          Background="#313244" ResizeDirection="Columns" ResizeBehavior="PreviousAndNext"
                          ShowsPreview="False" Cursor="SizeWE"
                          ToolTip="Drag left or right to resize the OU tree and Computer list"/>

            <!-- RIGHT PANE: AD COMPUTER OBJECTS -->
            <Border Grid.Column="2" Background="#181825" CornerRadius="6" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="💻 AD COMPUTER OBJECTS" FontWeight="Bold" Foreground="#A6E3A1" Margin="0,0,0,6"/>

                    <!-- Filter & Query Bar -->
                    <Grid Grid.Row="1" Margin="0,0,0,6">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="145"/>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="🔍 Filter:" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="0,0,6,0"/>
                        <TextBox x:Name="txtAdSearch" Grid.Column="1" Height="28" Margin="0,0,8,0"
                                 ToolTip="Filter displayed computers by Name, DNS Hostname, Operating System, OU, or Description"/>
                        <TextBlock Grid.Column="2" Text="OS Type:" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="0,0,6,0"/>
                        <ComboBox x:Name="cmbAdOsFilter" Grid.Column="3" Height="28" Margin="0,0,8,0" IsEditable="False">
                            <ComboBoxItem Content="All OS Types" IsSelected="True"/>
                            <ComboBoxItem Content="Workstations Only"/>
                            <ComboBoxItem Content="Servers Only"/>
                        </ComboBox>
                        <CheckBox x:Name="chkAdEnabledOnly" Grid.Column="4" Content="Enabled accounts only"
                                  IsChecked="True" Margin="0,0,8,0" VerticalAlignment="Center"
                                  ToolTip="Exclude disabled Active Directory computer accounts"/>
                        <Button x:Name="btnAdQuery" Grid.Column="5" Content="🔄 Query" Width="Auto" Height="28" Padding="10,2"
                                Background="#45475A" Foreground="#CDD6F4" Margin="0"
                                ToolTip="Re-query Active Directory for computers in the selected OU"/>
                    </Grid>

                    <!-- Selection Helper Bar -->
                    <WrapPanel Grid.Row="2" Margin="0,0,0,6">
                        <Button x:Name="btnAdCheckAll" Content="☑ Check All Shown" Width="Auto" Height="25" Padding="10,2" FontSize="11.5" Background="#45475A" Foreground="#CDD6F4" Margin="0,0,6,0"/>
                        <Button x:Name="btnAdUncheckAll" Content="☐ Uncheck All" Width="Auto" Height="25" Padding="10,2" FontSize="11.5" Background="#45475A" Foreground="#CDD6F4" Margin="0,0,6,0"/>
                        <Button x:Name="btnAdToggleHighlighted" Content="✔ Check Highlighted Rows" Width="Auto" Height="25" Padding="10,2" FontSize="11.5" Background="#45475A" Foreground="#CDD6F4" Margin="0,0,10,0"
                                ToolTip="Check all rows currently highlighted via Shift+Click or Ctrl+Click"/>
                        <TextBlock Text="Tip: Use checkboxes or Ctrl/Shift+Click to select multiple computers, or import an entire OU."
                                   Foreground="#A6ADC8" FontSize="11.5" VerticalAlignment="Center"/>
                    </WrapPanel>

                    <!-- Computers DataGrid -->
                    <DataGrid x:Name="dgAdComputers" Grid.Row="3" AutoGenerateColumns="False" CanUserAddRows="False"
                              CanUserSortColumns="True" SelectionMode="Extended" SelectionUnit="FullRow">
                        <DataGrid.Columns>
                            <DataGridTemplateColumn Header="Select" Width="55" CanUserSort="True" SortMemberPath="Selected">
                                <DataGridTemplateColumn.CellTemplate>
                                    <DataTemplate>
                                        <CheckBox IsChecked="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"
                                                  HorizontalAlignment="Center" VerticalAlignment="Center"
                                                  Focusable="False" Cursor="Hand"/>
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                            </DataGridTemplateColumn>
                            <DataGridTextColumn Header="Computer Name" Binding="{Binding Name}" Width="145" IsReadOnly="True" SortMemberPath="Name"/>
                            <DataGridTextColumn Header="Operating System" Binding="{Binding OperatingSystem}" Width="175" IsReadOnly="True" SortMemberPath="OperatingSystem"/>
                            <DataGridTextColumn Header="DNS Hostname" Binding="{Binding DNSHostName}" Width="170" IsReadOnly="True" SortMemberPath="DNSHostName"/>
                            <DataGridTextColumn Header="OU / Container" Binding="{Binding OUPath}" Width="*" IsReadOnly="True" SortMemberPath="OUPath"/>
                            <DataGridTextColumn Header="Description" Binding="{Binding Description}" Width="140" IsReadOnly="True" SortMemberPath="Description"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </Border>
        </Grid>

        <!-- FOOTER BAR -->
        <Border Grid.Row="2" Background="#181825" CornerRadius="6" Padding="10,8" Margin="0,8,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock x:Name="lblAdSummary" Grid.Column="0" Text="Ready. Click 'Connect / Load OUs' to browse Active Directory."
                           Foreground="#A6ADC8" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                <Button x:Name="btnAdImportOU" Grid.Column="1" Content="📥 Import Entire Selected OU" Width="Auto" Height="30" Padding="12,2"
                        Background="#CBA6F7" Foreground="#11111B" Margin="0,0,8,0"
                        ToolTip="Import all computers displayed in the currently selected OU / container"/>
                <Button x:Name="btnAdImportSelected" Grid.Column="2" Content="✔ Import Selected Computers" Width="Auto" Height="30" Padding="14,2"
                        Background="#A6E3A1" Foreground="#11111B" Margin="0,0,8,0"
                        ToolTip="Import all checked or highlighted computers into the Target Computers list"/>
                <Button x:Name="btnAdCancel" Grid.Column="3" Content="Cancel" Width="85" Height="30"
                        Background="#45475A" Foreground="#CDD6F4" Margin="0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $adReader = New-Object System.Xml.XmlNodeReader $adBrowserXaml
    $adWin    = [System.Windows.Markup.XamlReader]::Load($adReader)
    $adWin.Owner = $window

    $txtAdDomain            = $adWin.FindName("txtAdDomain")
    $btnAdConnect           = $adWin.FindName("btnAdConnect")
    $lblAdConnStatus        = $adWin.FindName("lblAdConnStatus")
    $chkAdIncludeSubOUs     = $adWin.FindName("chkAdIncludeSubOUs")
    $tvAdOUs                = $adWin.FindName("tvAdOUs")
    $txtAdSearch            = $adWin.FindName("txtAdSearch")
    $cmbAdOsFilter          = $adWin.FindName("cmbAdOsFilter")
    $chkAdEnabledOnly       = $adWin.FindName("chkAdEnabledOnly")
    $btnAdQuery             = $adWin.FindName("btnAdQuery")
    $btnAdCheckAll          = $adWin.FindName("btnAdCheckAll")
    $btnAdUncheckAll        = $adWin.FindName("btnAdUncheckAll")
    $btnAdToggleHighlighted = $adWin.FindName("btnAdToggleHighlighted")
    $dgAdComputers          = $adWin.FindName("dgAdComputers")
    $lblAdSummary           = $adWin.FindName("lblAdSummary")
    $btnAdImportOU          = $adWin.FindName("btnAdImportOU")
    $btnAdImportSelected    = $adWin.FindName("btnAdImportSelected")
    $btnAdCancel            = $adWin.FindName("btnAdCancel")

    $adSavedLayout = if ($script:UiLayoutState -and $script:UiLayoutState.ChildWindows -and $script:UiLayoutState.ChildWindows["AdBrowser"]) {
        $script:UiLayoutState.ChildWindows["AdBrowser"]
    } else { $null }

    if ($adSavedLayout -and -not [string]::IsNullOrWhiteSpace($adSavedLayout.LastImportedDomain)) {
        $txtAdDomain.Text = [string]$adSavedLayout.LastImportedDomain
    } else {
        $txtAdDomain.Text = Get-DefaultAdDomainName
    }
    if ($adSavedLayout -and $null -ne $adSavedLayout.LastImportedSubOUs) {
        $chkAdIncludeSubOUs.IsChecked = [bool]$adSavedLayout.LastImportedSubOUs
    }

    $script:AdAllComputers  = New-Object System.Collections.Generic.List[PSCustomObject]
    $script:AdViewComputers = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
    $dgAdComputers.ItemsSource = $script:AdViewComputers
    $script:AdBrowserState = @{
        ServerPrefix = ""
        RootDN       = ""
        SelectedDN   = ""
        SelectedName = ""
    }

    $script:UpdateAdBrowserSummary = {
        $checkedCount = @($script:AdViewComputers | Where-Object { $_.Selected }).Count
        $ouLabel = if ($script:AdBrowserState.SelectedName) { $script:AdBrowserState.SelectedName } else { "Selected Container" }
        $lblAdSummary.Text = "Showing $($script:AdViewComputers.Count) of $($script:AdAllComputers.Count) computer(s) in '$ouLabel' | $checkedCount checked"
    }

    $script:ApplyAdBrowserClientFilter = {
        $searchTxt = $txtAdSearch.Text.Trim()
        $osSelItem = $cmbAdOsFilter.SelectedItem
        $osMode    = if ($osSelItem -and $osSelItem.Content) { "$($osSelItem.Content)" } else { "All OS Types" }

        $script:AdViewComputers.Clear()
        foreach ($comp in $script:AdAllComputers) {
            if ($osMode -eq "Workstations Only" -and $comp.OperatingSystem -match '(?i)Server') { continue }
            if ($osMode -eq "Servers Only" -and $comp.OperatingSystem -notmatch '(?i)Server') { continue }
            if (-not [string]::IsNullOrWhiteSpace($searchTxt)) {
                $matched = ($comp.Name -like "*$searchTxt*") -or
                           ($comp.DNSHostName -like "*$searchTxt*") -or
                           ($comp.OperatingSystem -like "*$searchTxt*") -or
                           ($comp.OUPath -like "*$searchTxt*") -or
                           ($comp.Description -like "*$searchTxt*")
                if (-not $matched) { continue }
            }
            $script:AdViewComputers.Add($comp)
        }
        & $script:UpdateAdBrowserSummary
    }

    $script:QueryComputersForSelectedAdOU = {
        $selItem = $tvAdOUs.SelectedItem
        if (-not $selItem -or -not $selItem.Tag) { return }

        $targetDN   = "$($selItem.Tag.DistinguishedName)"
        $targetName = "$($selItem.Tag.DisplayName)"
        if ([string]::IsNullOrWhiteSpace($targetDN)) { return }

        $script:AdBrowserState.SelectedDN   = $targetDN
        $script:AdBrowserState.SelectedName = $targetName
        $lblAdSummary.Text    = "Querying Active Directory computers in '$targetName'..."
        Invoke-WpfDoEvents

        $entry    = $null
        $searcher = $null
        $results  = $null
        try {
            $ldapUrl = if ($script:AdBrowserState.ServerPrefix) { "LDAP://$($script:AdBrowserState.ServerPrefix)/$targetDN" } else { "LDAP://$targetDN" }
            $entry    = New-AdDirectoryEntry -LdapPath $ldapUrl
            $searcher = New-Object System.DirectoryServices.DirectorySearcher($entry)
            $searcher.PageSize = 500
            $searcher.ServerTimeLimit = [TimeSpan]::FromSeconds(15)
            $searcher.SearchScope = if ($chkAdIncludeSubOUs.IsChecked) {
                [System.DirectoryServices.SearchScope]::Subtree
            } else {
                [System.DirectoryServices.SearchScope]::OneLevel
            }

            if ($chkAdEnabledOnly.IsChecked) {
                $searcher.Filter = "(&(objectCategory=computer)(objectClass=computer)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
            } else {
                $searcher.Filter = "(&(objectCategory=computer)(objectClass=computer))"
            }

            [void]$searcher.PropertiesToLoad.AddRange(@("name", "cn", "dNSHostName", "operatingSystem", "description", "distinguishedName", "lastLogonTimestamp", "lastLogon"))
            $results = $searcher.FindAll()

            $script:AdAllComputers.Clear()
            $tempList = New-Object System.Collections.Generic.List[PSCustomObject]
            foreach ($res in $results) {
                $props = $res.Properties
                $cName = if ($props["name"] -and $props["name"].Count -gt 0) { "$($props["name"][0])" }
                         elseif ($props["cn"] -and $props["cn"].Count -gt 0) { "$($props["cn"][0])" }
                         else { "" }
                if ([string]::IsNullOrWhiteSpace($cName)) { continue }

                $dnsName = if ($props["dNSHostName"] -and $props["dNSHostName"].Count -gt 0) { "$($props["dNSHostName"][0])" } else { "" }
                $osName  = if ($props["operatingSystem"] -and $props["operatingSystem"].Count -gt 0) { "$($props["operatingSystem"][0])" } else { "Windows" }
                $descTxt = if ($props["description"] -and $props["description"].Count -gt 0) { "$($props["description"][0])" } else { "" }
                $dnTxt   = if ($props["distinguishedName"] -and $props["distinguishedName"].Count -gt 0) { "$($props["distinguishedName"][0])" } else { $targetDN }
                $canonOU = ConvertFrom-DistinguishedNameToCanonical -DistinguishedName $dnTxt

                $rawLogonTs = if ($props["lastLogonTimestamp"] -and $props["lastLogonTimestamp"].Count -gt 0) { $props["lastLogonTimestamp"][0] } else { $null }
                $rawLogon   = if ($props["lastLogon"] -and $props["lastLogon"].Count -gt 0) { $props["lastLogon"][0] } else { $null }
                $bestLogonRaw = if ($null -ne $rawLogonTs -and [int64]$rawLogonTs -gt 0) {
                    if ($null -ne $rawLogon -and [int64]$rawLogon -gt [int64]$rawLogonTs) { $rawLogon } else { $rawLogonTs }
                } else { $rawLogon }
                $adLastLogonTxt = ConvertFrom-AdFileTime -RawValue $bestLogonRaw

                $tempList.Add([PSCustomObject]@{
                    Selected          = $false
                    Name              = $cName
                    OperatingSystem   = $osName
                    DNSHostName       = $dnsName
                    OUPath            = $canonOU
                    ADLastLogon       = $adLastLogonTxt
                    Description       = $descTxt
                    DistinguishedName = $dnTxt
                })
            }

            foreach ($sortedComp in ($tempList | Sort-Object Name)) {
                $script:AdAllComputers.Add($sortedComp)
            }

            & $script:ApplyAdBrowserClientFilter
            Write-DiagnosticLog "AD Browser queried $($script:AdAllComputers.Count) computer(s) under '$targetDN'"
        } catch {
            $errMsg = $_.Exception.Message
            $lblAdSummary.Text = "AD query error: $errMsg"
            Write-DiagnosticLog "AD Browser query failed for '$targetDN': $errMsg" "WARN"
            [System.Windows.MessageBox]::Show("Failed to query computers from '$targetName':`n`n$errMsg", "Active Directory Query Error", "OK", "Warning")
        } finally {
            if ($null -ne $results)  { try { $results.Dispose() } catch {} }
            if ($null -ne $searcher) { try { $searcher.Dispose() } catch {} }
            if ($null -ne $entry)    { try { $entry.Dispose() } catch {} }
        }
    }

    $script:ConnectAndLoadAdOUs = {
        $domInput = $txtAdDomain.Text.Trim()
        $serverPrefix = $domInput
        $lblAdConnStatus.Text = "Connecting to Active Directory..."
        $lblAdConnStatus.Foreground = "#F9E2AF"
        Invoke-WpfDoEvents

        $rootDse  = $null
        $rootEntry = $null
        $ouSearcher = $null
        $ouResults  = $null
        try {
            $rootDsePath = if ($serverPrefix) { "LDAP://$serverPrefix/RootDSE" } else { "LDAP://RootDSE" }
            $rootDse = New-AdDirectoryEntry -LdapPath $rootDsePath
            $defaultNamingContext = "$($rootDse.Properties["defaultNamingContext"][0])"
            if ([string]::IsNullOrWhiteSpace($defaultNamingContext)) {
                throw "Could not retrieve defaultNamingContext from Active Directory RootDSE."
            }

            $script:AdBrowserState.ServerPrefix = $serverPrefix
            $script:AdBrowserState.RootDN       = $defaultNamingContext

            $authLabel = if ($script:AppSettings -and (-not $script:AppSettings.UseCurrentCred) -and $script:AppSettings.Username) {
                "Auth: $($script:AppSettings.Username)"
            } else {
                "Auth: Current Windows Logon"
            }
            $lblAdConnStatus.Text = "Connected: $defaultNamingContext ($authLabel)"
            $lblAdConnStatus.Foreground = "#A6E3A1"
            Invoke-WpfDoEvents

            $rootLdapPath = if ($serverPrefix) { "LDAP://$serverPrefix/$defaultNamingContext" } else { "LDAP://$defaultNamingContext" }
            $rootEntry    = New-AdDirectoryEntry -LdapPath $rootLdapPath
            $ouSearcher   = New-Object System.DirectoryServices.DirectorySearcher($rootEntry)
            $ouSearcher.PageSize = 500
            $ouSearcher.ServerTimeLimit = [TimeSpan]::FromSeconds(15)
            $ouSearcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
            $ouSearcher.Filter = "(|(objectCategory=organizationalUnit)(&(objectCategory=container)(cn=Computers)))"
            [void]$ouSearcher.PropertiesToLoad.AddRange(@("name", "ou", "cn", "distinguishedName", "objectClass"))
            $ouResults = $ouSearcher.FindAll()

            $tvAdOUs.Items.Clear()
            $domainFriendly = ($defaultNamingContext -split '(?<!\\),' | ForEach-Object {
                if ($_ -match '^(?i)DC=(.+)$') { $Matches[1] }
            }) -join '.'
            if ([string]::IsNullOrWhiteSpace($domainFriendly)) { $domainFriendly = $defaultNamingContext }

            $rootNode = New-Object System.Windows.Controls.TreeViewItem
            $rootNode.Header = "🌐 $domainFriendly"
            $rootNode.Tag = [PSCustomObject]@{
                DistinguishedName = $defaultNamingContext
                DisplayName       = $domainFriendly
            }
            $rootNode.IsExpanded = $true
            [void]$tvAdOUs.Items.Add($rootNode)

            $nodeMap = @{}
            $nodeMap[$defaultNamingContext.ToLowerInvariant()] = $rootNode

            $ouEntries = New-Object System.Collections.Generic.List[PSCustomObject]
            foreach ($r in $ouResults) {
                $p = $r.Properties
                $dn = if ($p["distinguishedName"] -and $p["distinguishedName"].Count -gt 0) { "$($p["distinguishedName"][0])" } else { "" }
                if ([string]::IsNullOrWhiteSpace($dn)) { continue }
                $disp = if ($p["ou"] -and $p["ou"].Count -gt 0) { "$($p["ou"][0])" }
                        elseif ($p["name"] -and $p["name"].Count -gt 0) { "$($p["name"][0])" }
                        elseif ($p["cn"] -and $p["cn"].Count -gt 0) { "$($p["cn"][0])" }
                        else { $dn }
                $depth = @($dn -split '(?<!\\),').Count
                $ouEntries.Add([PSCustomObject]@{
                    DN          = $dn
                    DisplayName = $disp
                    Depth       = $depth
                })
            }

            foreach ($item in ($ouEntries | Sort-Object Depth, DisplayName)) {
                $dnParts  = @($item.DN -split '(?<!\\),')
                $parentDN = if ($dnParts.Count -gt 1) { ($dnParts[1..($dnParts.Count - 1)] -join ',') } else { $defaultNamingContext }
                $parentKey = $parentDN.ToLowerInvariant()
                $parentNode = if ($nodeMap.ContainsKey($parentKey)) { $nodeMap[$parentKey] } else { $rootNode }

                $icon = if ($item.DN -match '^(?i)CN=Computers,') { "🖥" } else { "📁" }
                $childNode = New-Object System.Windows.Controls.TreeViewItem
                $childNode.Header = "$icon $($item.DisplayName)"
                $childNode.Tag = [PSCustomObject]@{
                    DistinguishedName = $item.DN
                    DisplayName       = $item.DisplayName
                }
                [void]$parentNode.Items.Add($childNode)
                $nodeMap[$item.DN.ToLowerInvariant()] = $childNode
            }

            $targetSelectNode = $rootNode
            $savedOuDn = if ($adSavedLayout -and -not [string]::IsNullOrWhiteSpace($adSavedLayout.LastImportedOuDN)) {
                [string]$adSavedLayout.LastImportedOuDN.Trim()
            } else { "" }

            if (-not [string]::IsNullOrWhiteSpace($savedOuDn)) {
                $savedKey = $savedOuDn.ToLowerInvariant()
                if ($nodeMap.ContainsKey($savedKey)) {
                    $targetSelectNode = $nodeMap[$savedKey]
                    $anc = $targetSelectNode.Parent
                    while ($anc -is [System.Windows.Controls.TreeViewItem]) {
                        $anc.IsExpanded = $true
                        $anc = $anc.Parent
                    }
                    $targetSelectNode.IsExpanded = $true
                }
            }

            $targetSelectNode.IsSelected = $true
            try {
                $tvAdOUs.UpdateLayout()
                $targetSelectNode.BringIntoView()
            } catch {}
            Write-DiagnosticLog "AD Browser loaded $($ouEntries.Count) OU/container node(s) from '$defaultNamingContext'"
        } catch {
            $errMsg = $_.Exception.Message
            $lblAdConnStatus.Text = "Connection failed: $errMsg"
            $lblAdConnStatus.Foreground = "#F38BA8"
            Write-DiagnosticLog "AD Browser connection failed: $errMsg" "WARN"
            [System.Windows.MessageBox]::Show("Unable to connect to Active Directory '$domInput':`n`n$errMsg`n`nVerify that this machine can reach a Domain Controller or configure Domain Admin credentials in Settings.", "Active Directory Connection Error", "OK", "Warning")
        } finally {
            if ($null -ne $ouResults)  { try { $ouResults.Dispose() } catch {} }
            if ($null -ne $ouSearcher) { try { $ouSearcher.Dispose() } catch {} }
            if ($null -ne $rootEntry)  { try { $rootEntry.Dispose() } catch {} }
            if ($null -ne $rootDse)    { try { $rootDse.Dispose() } catch {} }
        }
    }

    $btnAdConnect.Add_Click($script:ConnectAndLoadAdOUs)
    $txtAdDomain.Add_KeyDown({
        param($s, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Return) {
            & $script:ConnectAndLoadAdOUs
        }
    })

    $tvAdOUs.Add_SelectedItemChanged({
        & $script:QueryComputersForSelectedAdOU
    })

    $chkAdIncludeSubOUs.Add_Click({
        if ($tvAdOUs.SelectedItem) { & $script:QueryComputersForSelectedAdOU }
    })

    $chkAdEnabledOnly.Add_Click({
        if ($tvAdOUs.SelectedItem) { & $script:QueryComputersForSelectedAdOU }
    })

    $btnAdQuery.Add_Click({
        if ($tvAdOUs.SelectedItem) {
            & $script:QueryComputersForSelectedAdOU
        } else {
            & $script:ConnectAndLoadAdOUs
        }
    })

    $txtAdSearch.Add_TextChanged({
        & $script:ApplyAdBrowserClientFilter
    })

    $cmbAdOsFilter.Add_SelectionChanged({
        & $script:ApplyAdBrowserClientFilter
    })

    $btnAdCheckAll.Add_Click({
        foreach ($c in $script:AdViewComputers) { $c.Selected = $true }
        $dgAdComputers.Items.Refresh()
        & $script:UpdateAdBrowserSummary
    })

    $btnAdUncheckAll.Add_Click({
        foreach ($c in $script:AdAllComputers) { $c.Selected = $false }
        $dgAdComputers.Items.Refresh()
        & $script:UpdateAdBrowserSummary
    })

    $btnAdToggleHighlighted.Add_Click({
        $selRows = @($dgAdComputers.SelectedItems)
        if ($selRows.Count -eq 0) { return }
        foreach ($r in $selRows) {
            if ($null -ne $r.PSObject.Properties['Selected']) {
                $r.Selected = $true
            }
        }
        $dgAdComputers.Items.Refresh()
        & $script:UpdateAdBrowserSummary
    })

    $dgAdComputers.AddHandler(
        [System.Windows.Controls.Primitives.ToggleButton]::ClickEvent,
        [System.Windows.RoutedEventHandler]{
            param($sender, $e)
            if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
                & $script:UpdateAdBrowserSummary
            }
        }
    )

    $dgAdComputers.Add_MouseDoubleClick({
        $cur = $dgAdComputers.SelectedItem
        if ($cur -and $null -ne $cur.PSObject.Properties['Selected']) {
            $cur.Selected = -not [bool]$cur.Selected
            $dgAdComputers.Items.Refresh()
            & $script:UpdateAdBrowserSummary
        }
    })

    $script:SaveLastImportedAdOuState = {
        try {
            if ($script:UiLayoutState -and $script:UiLayoutState.ChildWindows -and $script:UiLayoutState.ChildWindows["AdBrowser"]) {
                $adCw = $script:UiLayoutState.ChildWindows["AdBrowser"]
                if (-not [string]::IsNullOrWhiteSpace($script:AdBrowserState.SelectedDN)) {
                    $adCw.LastImportedOuDN = [string]$script:AdBrowserState.SelectedDN
                }
                if (-not [string]::IsNullOrWhiteSpace($txtAdDomain.Text)) {
                    $adCw.LastImportedDomain = [string]$txtAdDomain.Text.Trim()
                }
                $adCw.LastImportedSubOUs = ($chkAdIncludeSubOUs.IsChecked -eq $true)
                Save-UiLayoutState
            }
        } catch {}
    }

    $btnAdImportOU.Add_Click({
        if ($script:AdViewComputers.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No computers are currently listed in the selected OU to import.", "Import OU", "OK", "Information")
            return
        }
        $ouTitle = if ($script:AdBrowserState.SelectedName) { $script:AdBrowserState.SelectedName } else { "Selected OU" }
        $ans = [System.Windows.MessageBox]::Show("Import all $($script:AdViewComputers.Count) computer(s) displayed from '$ouTitle' into Computer Inventory?", "Confirm OU Import", "YesNo", "Question")
        if ($ans -ne 'Yes') { return }

        $itemsToImport = @($script:AdViewComputers | Where-Object { $_ -and $_.Name } | ForEach-Object {
            [PSCustomObject]@{
                ComputerName      = $_.Name
                OUPath            = $_.OUPath
                ADLastLogon       = $_.ADLastLogon
                DistinguishedName = $_.DistinguishedName
                Source            = "ADImport"
            }
        })
        & $script:SaveLastImportedAdOuState
        $adWin.Close()
        Write-DiagnosticLog "Importing $($itemsToImport.Count) computer(s) from AD OU '$ouTitle'"
        Add-TargetComputers -ComputerItems $itemsToImport -DefaultSource "ADImport"
    })

    $btnAdImportSelected.Add_Click({
        $checkedItems     = @($script:AdAllComputers | Where-Object { $_.Selected })
        $highlightedItems = @($dgAdComputers.SelectedItems | Where-Object { $_ -and $_.Name })
        $combinedNames    = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $combinedItems    = New-Object System.Collections.Generic.List[PSCustomObject]

        foreach ($item in ($checkedItems + $highlightedItems)) {
            if ($item -and $item.Name -and $combinedNames.Add($item.Name)) {
                $combinedItems.Add([PSCustomObject]@{
                    ComputerName      = $item.Name
                    OUPath            = $item.OUPath
                    ADLastLogon       = $item.ADLastLogon
                    DistinguishedName = $item.DistinguishedName
                    Source            = "ADImport"
                })
            }
        }

        if ($combinedItems.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please check one or more computers (or highlight rows in the table) to import.", "Import Selected Computers", "OK", "Information")
            return
        }

        & $script:SaveLastImportedAdOuState
        $adWin.Close()
        Write-DiagnosticLog "Importing $($combinedItems.Count) selected computer(s) from Active Directory"
        Add-TargetComputers -ComputerItems $combinedItems.ToArray() -DefaultSource "ADImport"
    })

    $btnAdCancel.Add_Click({
        $adWin.Close()
    })

    $adWin.Add_ContentRendered({
        if (-not [string]::IsNullOrWhiteSpace($txtAdDomain.Text)) {
            & $script:ConnectAndLoadAdOUs
        }
    })

    $colAdOuTree = $adWin.FindName("colAdOuTree")
    Register-ChildWindowLayoutPersistence -Dialog $adWin -WindowKey "AdBrowser" -LeftColumn $colAdOuTree -LeftColumnProp "OuTreeWidth"
    [void]$adWin.ShowDialog()
}

# ==========================================
# 5C. PDQ-STYLE ACTIVE DIRECTORY SYNC ENGINE & UI
# ==========================================
$script:AdSyncConfig = [PSCustomObject]@{
    AutoSyncEnabled       = $false
    SyncDays              = 0
    SyncHours             = 4
    SyncMinutes           = 0
    DeleteMode            = "Import Only"
    SyncDisabledComputers = $false
    Domain                = ""
    Containers            = @()
    LastSyncTime          = "Never"
    LastSyncStatus        = "Not synced yet"
}
$script:AdAutoSyncTimer = $null

function Load-AdSyncConfig {
    if ($script:AdSyncConfigFilePath -and (Test-Path -LiteralPath $script:AdSyncConfigFilePath)) {
        try {
            $raw = [System.IO.File]::ReadAllText($script:AdSyncConfigFilePath, [System.Text.Encoding]::UTF8)
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $obj = ConvertFrom-Json -InputObject $raw
                if ($null -ne $obj) {
                    $containersList = @()
                    if ($obj.Containers) {
                        foreach ($c in @($obj.Containers)) {
                            if ($c -and -not [string]::IsNullOrWhiteSpace("$($c.DistinguishedName)")) {
                                $incType = if ($c.SyncType -eq "Exclude") { "Exclude" } else { "Include" }
                                $incSub  = if ($null -ne $c.PSObject.Properties['IncludeSubtree']) { [bool]$c.IncludeSubtree } else { $true }
                                $canPath = if (-not [string]::IsNullOrWhiteSpace("$($c.CanonicalPath)")) {
                                    "$($c.CanonicalPath)"
                                } else {
                                    ConvertFrom-DistinguishedNameToCanonical -DistinguishedName "$($c.DistinguishedName)" -IsContainerDN
                                }
                                $containersList += [PSCustomObject]@{
                                    SyncType          = $incType
                                    IncludedGlyph     = if ($incType -eq "Include") { "✔" } else { "✖" }
                                    IncludeSubtree    = $incSub
                                    SubtreeGlyph      = if ($incSub) { "✔" } else { "—" }
                                    CanonicalPath     = $canPath
                                    DistinguishedName = "$($c.DistinguishedName)"
                                    Domain            = if ($c.Domain) { "$($c.Domain)" } else { "" }
                                }
                            }
                        }
                    }
                    $script:AdSyncConfig = [PSCustomObject]@{
                        AutoSyncEnabled       = [bool]$obj.AutoSyncEnabled
                        SyncDays              = if ($null -ne $obj.SyncDays) { [Math]::Max(0, [int]$obj.SyncDays) } else { 0 }
                        SyncHours             = if ($null -ne $obj.SyncHours) { [Math]::Max(0, [int]$obj.SyncHours) } else { 4 }
                        SyncMinutes           = if ($null -ne $obj.SyncMinutes) { [Math]::Max(0, [int]$obj.SyncMinutes) } else { 0 }
                        DeleteMode            = if ($obj.DeleteMode -in @("Full Sync", "Mixed Sync", "Import Only")) { "$($obj.DeleteMode)" } else { "Import Only" }
                        SyncDisabledComputers = [bool]$obj.SyncDisabledComputers
                        Domain                = if ($obj.Domain) { "$($obj.Domain)" } else { Get-DefaultAdDomainName }
                        Containers            = $containersList
                        LastSyncTime          = if ($obj.LastSyncTime) { "$($obj.LastSyncTime)" } else { "Never" }
                        LastSyncStatus        = if ($obj.LastSyncStatus) { "$($obj.LastSyncStatus)" } else { "Not synced yet" }
                    }
                }
            }
        } catch {
            Write-DiagnosticLog "Failed to load AD Sync config: $($_.Exception.Message)" "WARN"
        }
    }
    if ([string]::IsNullOrWhiteSpace($script:AdSyncConfig.Domain)) {
        $script:AdSyncConfig.Domain = Get-DefaultAdDomainName
    }
}

function Save-AdSyncConfig {
    try {
        if (-not $script:AdSyncConfigFilePath) { return }
        $serializable = [ordered]@{
            AutoSyncEnabled       = [bool]$script:AdSyncConfig.AutoSyncEnabled
            SyncDays              = [int]$script:AdSyncConfig.SyncDays
            SyncHours             = [int]$script:AdSyncConfig.SyncHours
            SyncMinutes           = [int]$script:AdSyncConfig.SyncMinutes
            DeleteMode            = "$($script:AdSyncConfig.DeleteMode)"
            SyncDisabledComputers = [bool]$script:AdSyncConfig.SyncDisabledComputers
            Domain                = "$($script:AdSyncConfig.Domain)"
            LastSyncTime          = "$($script:AdSyncConfig.LastSyncTime)"
            LastSyncStatus        = "$($script:AdSyncConfig.LastSyncStatus)"
            Containers            = @($script:AdSyncConfig.Containers | ForEach-Object {
                [ordered]@{
                    SyncType          = "$($_.SyncType)"
                    IncludeSubtree    = [bool]$_.IncludeSubtree
                    CanonicalPath     = "$($_.CanonicalPath)"
                    DistinguishedName = "$($_.DistinguishedName)"
                    Domain            = "$($_.Domain)"
                }
            })
        }
        $json = ConvertTo-Json -InputObject $serializable -Depth 5
        [System.IO.File]::WriteAllText($script:AdSyncConfigFilePath, $json, [System.Text.Encoding]::UTF8)
    } catch {
        Write-DiagnosticLog "Failed to save AD Sync config: $($_.Exception.Message)" "WARN"
    }
}

function Update-AdSyncStatusBadge {
    if (-not $lblAdSyncStatusBadge) { return }
    $ouCount = if ($script:AdSyncConfig -and $script:AdSyncConfig.Containers) {
        @($script:AdSyncConfig.Containers | Where-Object { $_.SyncType -ne "Exclude" }).Count
    } else { 0 }
    $autoTxt = if ($script:AdSyncConfig -and $script:AdSyncConfig.AutoSyncEnabled) {
        "Auto ($($script:AdSyncConfig.SyncDays)d $($script:AdSyncConfig.SyncHours)h $($script:AdSyncConfig.SyncMinutes)m)"
    } else {
        "Manual"
    }
    $lastTxt = if ($script:AdSyncConfig -and $script:AdSyncConfig.LastSyncTime -and $script:AdSyncConfig.LastSyncTime -ne "Never") {
        $script:AdSyncConfig.LastSyncTime
    } else {
        "Never"
    }
    $lblAdSyncStatusBadge.Text = "AD Sync: $autoTxt | $ouCount OU(s) | Last Sync: $lastTxt"
}

function Update-AdAutoSyncTimer {
    if ($null -eq $script:AdAutoSyncTimer) {
        $script:AdAutoSyncTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:AdAutoSyncTimer.Add_Tick({
            if ($script:AppIsClosing) { return }
            Write-DiagnosticLog "Scheduled AD Auto-Sync timer triggered."
            [void](Invoke-AdSync -Silent)
        })
    }
    $script:AdAutoSyncTimer.Stop()
    if ($script:AdSyncConfig -and [bool]$script:AdSyncConfig.AutoSyncEnabled) {
        $totalMins = ([int]$script:AdSyncConfig.SyncDays * 1440) + ([int]$script:AdSyncConfig.SyncHours * 60) + ([int]$script:AdSyncConfig.SyncMinutes)
        if ($totalMins -lt 1) { $totalMins = 15 }
        $script:AdAutoSyncTimer.Interval = [TimeSpan]::FromMinutes($totalMins)
        $script:AdAutoSyncTimer.Start()
        Write-DiagnosticLog "AD Auto-Sync timer enabled (every $totalMins minute(s))."
    }
    Update-AdSyncStatusBadge
}

function Test-DistinguishedNameInContainer {
    param(
        [string]$ObjectDN,
        [string]$ContainerDN,
        [bool]$IncludeSubtree = $true
    )
    if ([string]::IsNullOrWhiteSpace($ObjectDN) -or [string]::IsNullOrWhiteSpace($ContainerDN)) { return $false }
    $suffix = ",$ContainerDN"
    if (-not $ObjectDN.EndsWith($suffix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    if ($IncludeSubtree) { return $true }
    $prefix = $ObjectDN.Substring(0, $ObjectDN.Length - $suffix.Length)
    $parts = @($prefix -split '(?<!\\),')
    return ($parts.Count -eq 1)
}

function Invoke-AdSync {
    param([switch]$Silent)

    $containers = @($script:AdSyncConfig.Containers)
    $includedContainers = @($containers | Where-Object { $_.SyncType -ne "Exclude" })
    $excludedContainers = @($containers | Where-Object { $_.SyncType -eq "Exclude" })

    if ($includedContainers.Count -eq 0) {
        if (-not $Silent) {
            [System.Windows.MessageBox]::Show("No Included AD containers are configured.`n`nClick 'Include Container' to select one or more Active Directory OUs/containers to sync.", "Active Directory Sync", "OK", "Information")
        }
        return $false
    }

    $defaultDomain = if (-not [string]::IsNullOrWhiteSpace($script:AdSyncConfig.Domain)) {
        $script:AdSyncConfig.Domain.Trim()
    } else {
        Get-DefaultAdDomainName
    }

    $lblStatus.Text = "Syncing Active Directory computer inventory across $($includedContainers.Count) container(s)..."
    Invoke-WpfDoEvents

    $syncedByHost = @{}
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($inc in $includedContainers) {
        $targetDN = "$($inc.DistinguishedName)".Trim()
        if ([string]::IsNullOrWhiteSpace($targetDN)) { continue }
        $srvPrefix = if (-not [string]::IsNullOrWhiteSpace("$($inc.Domain)")) { "$($inc.Domain)".Trim() } else { $defaultDomain }

        $entry    = $null
        $searcher = $null
        $results  = $null
        try {
            $ldapUrl  = if ($srvPrefix) { "LDAP://$srvPrefix/$targetDN" } else { "LDAP://$targetDN" }
            $entry    = New-AdDirectoryEntry -LdapPath $ldapUrl
            $searcher = New-Object System.DirectoryServices.DirectorySearcher($entry)
            $searcher.PageSize = 500
            $searcher.ServerTimeLimit = [TimeSpan]::FromSeconds(20)
            $searcher.SearchScope = if ($null -eq $inc.IncludeSubtree -or [bool]$inc.IncludeSubtree) {
                [System.DirectoryServices.SearchScope]::Subtree
            } else {
                [System.DirectoryServices.SearchScope]::OneLevel
            }

            if ([bool]$script:AdSyncConfig.SyncDisabledComputers) {
                $searcher.Filter = "(&(objectCategory=computer)(objectClass=computer))"
            } else {
                $searcher.Filter = "(&(objectCategory=computer)(objectClass=computer)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
            }

            [void]$searcher.PropertiesToLoad.AddRange(@("name", "cn", "dNSHostName", "operatingSystem", "description", "distinguishedName", "lastLogonTimestamp", "lastLogon"))
            $results = $searcher.FindAll()

            foreach ($res in $results) {
                $props = $res.Properties
                $cName = if ($props["name"] -and $props["name"].Count -gt 0) { "$($props["name"][0])" }
                         elseif ($props["cn"] -and $props["cn"].Count -gt 0) { "$($props["cn"][0])" }
                         else { "" }
                if ([string]::IsNullOrWhiteSpace($cName)) { continue }
                $dnTxt = if ($props["distinguishedName"] -and $props["distinguishedName"].Count -gt 0) { "$($props["distinguishedName"][0])" } else { "CN=$cName,$targetDN" }

                # Check Exclude containers
                $isExcluded = $false
                foreach ($exc in $excludedContainers) {
                    $excSub = if ($null -eq $exc.IncludeSubtree) { $true } else { [bool]$exc.IncludeSubtree }
                    if (Test-DistinguishedNameInContainer -ObjectDN $dnTxt -ContainerDN "$($exc.DistinguishedName)" -IncludeSubtree $excSub) {
                        $isExcluded = $true
                        break
                    }
                }
                if ($isExcluded) { continue }

                $canonOU = ConvertFrom-DistinguishedNameToCanonical -DistinguishedName $dnTxt
                $rawLogonTs = if ($props["lastLogonTimestamp"] -and $props["lastLogonTimestamp"].Count -gt 0) { $props["lastLogonTimestamp"][0] } else { $null }
                $rawLogon   = if ($props["lastLogon"] -and $props["lastLogon"].Count -gt 0) { $props["lastLogon"][0] } else { $null }
                $bestLogonRaw = if ($null -ne $rawLogonTs -and [int64]$rawLogonTs -gt 0) {
                    if ($null -ne $rawLogon -and [int64]$rawLogon -gt [int64]$rawLogonTs) { $rawLogon } else { $rawLogonTs }
                } else { $rawLogon }
                $adLastLogonTxt = ConvertFrom-AdFileTime -RawValue $bestLogonRaw

                $key = $cName.ToUpperInvariant()
                $syncedByHost[$key] = [PSCustomObject]@{
                    ComputerName      = $cName
                    OUPath            = $canonOU
                    ADLastLogon       = $adLastLogonTxt
                    DistinguishedName = $dnTxt
                    Source            = "ADSync"
                }
            }
        } catch {
            $errors.Add("$($inc.CanonicalPath): $($_.Exception.Message)")
        } finally {
            if ($null -ne $results)  { try { $results.Dispose() } catch {} }
            if ($null -ne $searcher) { try { $searcher.Dispose() } catch {} }
            if ($null -ne $entry)    { try { $entry.Dispose() } catch {} }
        }
    }

    if ($errors.Count -gt 0 -and $syncedByHost.Count -eq 0) {
        $errSummary = $errors -join "`n"
        $script:AdSyncConfig.LastSyncTime   = (Get-Date).ToString("M/d/yyyy h:mm:ss tt")
        $script:AdSyncConfig.LastSyncStatus = "Error ($($errors[0]))"
        Save-AdSyncConfig
        Update-AdSyncStatusBadge
        $lblStatus.Text = "AD Sync failed: $($errors[0])"
        Write-DiagnosticLog "AD Sync failed: $errSummary" "WARN"
        if (-not $Silent) {
            [System.Windows.MessageBox]::Show("Active Directory Sync encountered error(s):`n`n$errSummary", "AD Sync Error", "OK", "Warning")
        }
        return $false
    }

    # Apply Delete Mode ("Full Sync", "Mixed Sync", "Import Only")
    $delMode = "$($script:AdSyncConfig.DeleteMode)"
    $removedCount = 0
    if ($delMode -eq "Full Sync" -or $delMode -eq "Mixed Sync") {
        $toRemove = New-Object System.Collections.Generic.List[object]
        foreach ($existing in @($script:TargetsCollection)) {
            $k = "$($existing.ComputerName)".ToUpperInvariant()
            if (-not $syncedByHost.ContainsKey($k)) {
                $src = if ($null -ne $existing.PSObject.Properties['Source'] -and $existing.Source) { "$($existing.Source)" } else { "Manual" }
                if ($delMode -eq "Full Sync") {
                    $toRemove.Add($existing)
                } elseif ($delMode -eq "Mixed Sync" -and ($src -eq "ADSync" -or $src -eq "ADImport")) {
                    $toRemove.Add($existing)
                }
            }
        }
        foreach ($rem in $toRemove) {
            [void]$script:TargetsCollection.Remove($rem)
            $removedCount++
        }
    }

    if ($syncedByHost.Count -gt 0) {
        Add-TargetComputers -ComputerItems @($syncedByHost.Values) -DefaultSource "ADSync" -SkipSave
    }

    Save-ComputerInventory
    Invoke-RefreshTargetsFilter
    Update-TargetCountSummary

    $nowStr = (Get-Date).ToString("M/d/yyyy h:mm:ss tt")
    $script:AdSyncConfig.LastSyncTime = $nowStr
    $statusNote = if ($errors.Count -gt 0) {
        "Partial ($($syncedByHost.Count) synced, $($errors.Count) OU error)"
    } else {
        "Success ($($syncedByHost.Count) Computers Synced)"
    }
    $script:AdSyncConfig.LastSyncStatus = $statusNote
    Save-AdSyncConfig
    Update-AdSyncStatusBadge

    $lblStatus.Text = "AD Sync complete: $($syncedByHost.Count) computer(s) synced ($removedCount removed by '$delMode' mode)."
    Write-DiagnosticLog "AD Sync completed: $($syncedByHost.Count) computer(s) synced, $removedCount removed (Mode: $delMode)."
    return $true
}

function Set-AdPickerDescendantChecks {
    param(
        [System.Windows.Controls.TreeViewItem]$ParentNode,
        [bool]$TargetChecked
    )
    if ($null -eq $ParentNode) { return }
    foreach ($childItem in $ParentNode.Items) {
        if ($childItem -is [System.Windows.Controls.TreeViewItem]) {
            $childChk = $childItem.Header
            if ($childChk -is [System.Windows.Controls.CheckBox]) {
                $childChk.IsChecked = $TargetChecked
            }
            Set-AdPickerDescendantChecks -ParentNode $childItem -TargetChecked $TargetChecked
        }
    }
}

function Test-AdPickerHasUncheckedDescendant {
    param(
        [System.Windows.Controls.TreeViewItem]$Node
    )
    if ($null -eq $Node) { return $false }
    foreach ($child in $Node.Items) {
        if ($child -is [System.Windows.Controls.TreeViewItem]) {
            $cBox = $child.Header
            if ($cBox -is [System.Windows.Controls.CheckBox] -and $cBox.IsChecked -ne $true) {
                return $true
            }
            if (Test-AdPickerHasUncheckedDescendant -Node $child) {
                return $true
            }
        }
    }
    return $false
}

function Select-AdContainersDialog {
    param(
        [string]$SyncType = "Include",
        [string]$InitialDomain = ""
    )
    $modeTitle = if ($SyncType -eq "Exclude") { "Exclude Active Directory Containers" } else { "Include Active Directory Containers" }
    [xml]$pickerXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$modeTitle"
        Width="680" Height="560" MinWidth="540" MinHeight="420"
        ResizeMode="CanResizeWithGrip"
        WindowStartupLocation="CenterOwner"
        Background="#1E1E2E" Foreground="#CDD6F4" FontFamily="Segoe UI" FontSize="12.5">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="CaretBrush" Value="#89B4FA"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#181825" BorderBrush="#313244" BorderThickness="1" CornerRadius="6" Padding="10,8" Margin="0,0,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Domain / DC:" VerticalAlignment="Center" Foreground="#A6ADC8" Margin="0,0,8,0"/>
                <TextBox Grid.Column="1" Name="txtPickerDomain" Height="28" Margin="0,0,8,0" ToolTip="Active Directory Domain or Domain Controller"/>
                <Button Grid.Column="2" Name="btnPickerConnect" Content="🔄 Load OUs" Height="28" Background="#89B4FA" Foreground="#11111B" FontWeight="SemiBold"/>
            </Grid>
        </Border>

        <Grid Grid.Row="1" Margin="2,0,2,6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Name="lblPickerStatus" Text="Check one or more OUs / containers below to add to AD Sync:" Foreground="#A6ADC8" VerticalAlignment="Center"/>
            <CheckBox Grid.Column="1" Name="chkPickerSubtree" Content="Include Subtree (Sub-OUs) for selected containers" IsChecked="True" FontWeight="SemiBold" Foreground="#A6E3A1"/>
        </Grid>

        <Border Grid.Row="2" Background="#181825" BorderBrush="#313244" BorderThickness="1" CornerRadius="6" Padding="6">
            <TreeView Name="tvPickerOUs" Background="Transparent" BorderThickness="0" Foreground="#CDD6F4"/>
        </Border>

        <Grid Grid.Row="3" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Name="lblPickerCheckedCount" Text="0 container(s) checked" Foreground="#89B4FA" VerticalAlignment="Center"/>
            <Button Grid.Column="1" Name="btnPickerOk" Content="✔ Add Checked Container(s)" Width="190" Height="32" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" Margin="0,0,8,0"/>
            <Button Grid.Column="2" Name="btnPickerCancel" Content="Cancel" Width="90" Height="32"/>
        </Grid>
    </Grid>
</Window>
"@

    $pReader = New-Object System.Xml.XmlNodeReader($pickerXaml)
    $pWin    = [Windows.Markup.XamlReader]::Load($pReader)
    $pWin.Owner = $window

    $txtPickerDomain       = $pWin.FindName("txtPickerDomain")
    $btnPickerConnect      = $pWin.FindName("btnPickerConnect")
    $lblPickerStatus       = $pWin.FindName("lblPickerStatus")
    $chkPickerSubtree      = $pWin.FindName("chkPickerSubtree")
    $tvPickerOUs           = $pWin.FindName("tvPickerOUs")
    $lblPickerCheckedCount = $pWin.FindName("lblPickerCheckedCount")
    $btnPickerOk           = $pWin.FindName("btnPickerOk")
    $btnPickerCancel       = $pWin.FindName("btnPickerCancel")

    $txtPickerDomain.Text = if (-not [string]::IsNullOrWhiteSpace($InitialDomain)) { $InitialDomain } else { Get-DefaultAdDomainName }
    $script:PickerAllCheckBoxes       = New-Object System.Collections.Generic.List[System.Windows.Controls.CheckBox]
    $script:PickerCheckState          = @{ IsBulkUpdating = $false }
    $script:PickerCheckedCountLabel   = $lblPickerCheckedCount
    $script:PickedAdContainers        = @()

    $script:UpdateAdPickerCheckedSummary = {
        if ($null -eq $script:PickerAllCheckBoxes) { return }
        $cnt = @($script:PickerAllCheckBoxes | Where-Object { $_.IsChecked -eq $true }).Count
        if ($script:PickerCheckedCountLabel) {
            $script:PickerCheckedCountLabel.Text = "$cnt container(s) checked"
        }
    }

    $script:LoadAdPickerTree = {
        $dom = $txtPickerDomain.Text.Trim()
        $lblPickerStatus.Text = "Loading Active Directory OU hierarchy..."
        Invoke-WpfDoEvents

        $rootDse = $null
        $rootEntry = $null
        $ouSearcher = $null
        $ouResults = $null
        try {
            $rootDsePath = if ($dom) { "LDAP://$dom/RootDSE" } else { "LDAP://RootDSE" }
            $rootDse = New-AdDirectoryEntry -LdapPath $rootDsePath
            $defaultNC = "$($rootDse.Properties["defaultNamingContext"][0])"
            if ([string]::IsNullOrWhiteSpace($defaultNC)) {
                throw "Could not retrieve defaultNamingContext from RootDSE."
            }

            $rootLdap = if ($dom) { "LDAP://$dom/$defaultNC" } else { "LDAP://$defaultNC" }
            $rootEntry = New-AdDirectoryEntry -LdapPath $rootLdap
            $ouSearcher = New-Object System.DirectoryServices.DirectorySearcher($rootEntry)
            $ouSearcher.PageSize = 500
            $ouSearcher.ServerTimeLimit = [TimeSpan]::FromSeconds(15)
            $ouSearcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
            $ouSearcher.Filter = "(|(objectClass=organizationalUnit)(&(objectClass=container)(|(cn=Computers)(cn=Builtin))))"
            [void]$ouSearcher.PropertiesToLoad.AddRange(@("name", "ou", "cn", "distinguishedName", "objectClass"))
            $ouResults = $ouSearcher.FindAll()

            $tvPickerOUs.Items.Clear()
            $script:PickerAllCheckBoxes.Clear()
            if ($null -eq $script:PickerCheckState) {
                $script:PickerCheckState = @{ IsBulkUpdating = $false }
            } else {
                $script:PickerCheckState.IsBulkUpdating = $false
            }

            $nodeMap = @{}
            $domainCanon = ConvertFrom-DistinguishedNameToCanonical -DistinguishedName $defaultNC -IsContainerDN

            $makeCheckItem = {
                param([string]$LabelText, [string]$DN, [string]$CanonPath, [bool]$Expand = $false)
                $tvi = New-Object System.Windows.Controls.TreeViewItem
                $tvi.IsExpanded = $Expand
                $chk = New-Object System.Windows.Controls.CheckBox
                $chk.Content = $LabelText
                $chk.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CDD6F4")
                $chk.Margin = New-Object System.Windows.Thickness(2, 2, 4, 2)
                $chk.Tag = [PSCustomObject]@{
                    DistinguishedName = $DN
                    CanonicalPath     = $CanonPath
                    Domain            = $dom
                    TreeViewItem      = $tvi
                    CheckBox          = $chk
                }
                $chk.Add_Checked({
                    param($sender, $e)
                    if ($null -eq $script:PickerCheckState) {
                        $script:PickerCheckState = @{ IsBulkUpdating = $false }
                    }
                    if (-not $script:PickerCheckState.IsBulkUpdating) {
                        $script:PickerCheckState.IsBulkUpdating = $true
                        try {
                            if ($sender.Tag -and $sender.Tag.TreeViewItem) {
                                Set-AdPickerDescendantChecks -ParentNode $sender.Tag.TreeViewItem -TargetChecked $true
                            }
                        } finally {
                            $script:PickerCheckState.IsBulkUpdating = $false
                        }
                    }
                    if ($script:UpdateAdPickerCheckedSummary) {
                        & $script:UpdateAdPickerCheckedSummary
                    }
                })
                $chk.Add_Unchecked({
                    param($sender, $e)
                    if ($null -eq $script:PickerCheckState) {
                        $script:PickerCheckState = @{ IsBulkUpdating = $false }
                    }
                    if (-not $script:PickerCheckState.IsBulkUpdating) {
                        $script:PickerCheckState.IsBulkUpdating = $true
                        try {
                            if ($sender.Tag -and $sender.Tag.TreeViewItem) {
                                Set-AdPickerDescendantChecks -ParentNode $sender.Tag.TreeViewItem -TargetChecked $false
                            }
                        } finally {
                            $script:PickerCheckState.IsBulkUpdating = $false
                        }
                    }
                    if ($script:UpdateAdPickerCheckedSummary) {
                        & $script:UpdateAdPickerCheckedSummary
                    }
                })
                $script:PickerAllCheckBoxes.Add($chk)
                $tvi.Header = $chk
                $tvi.Tag = $chk.Tag
                return $tvi
            }

            $rootItem = & $makeCheckItem "🌐 $domainCanon (Entire Domain)" $defaultNC $domainCanon $true
            $nodeMap[$defaultNC.ToUpperInvariant()] = $rootItem

            $ouList = New-Object System.Collections.Generic.List[PSCustomObject]
            foreach ($r in $ouResults) {
                $p = $r.Properties
                $dn = if ($p["distinguishedName"] -and $p["distinguishedName"].Count -gt 0) { "$($p["distinguishedName"][0])" } else { "" }
                if ([string]::IsNullOrWhiteSpace($dn) -or $dn -ieq $defaultNC) { continue }
                $n = if ($p["ou"] -and $p["ou"].Count -gt 0) { "$($p["ou"][0])" }
                     elseif ($p["name"] -and $p["name"].Count -gt 0) { "$($p["name"][0])" }
                     elseif ($p["cn"] -and $p["cn"].Count -gt 0) { "$($p["cn"][0])" }
                     else { $dn }
                $depth = @($dn -split '(?<!\\),').Count
                $ouList.Add([PSCustomObject]@{
                    Name  = $n
                    DN    = $dn
                    Depth = $depth
                })
            }

            foreach ($ou in ($ouList | Sort-Object Depth, Name)) {
                $canon = ConvertFrom-DistinguishedNameToCanonical -DistinguishedName $ou.DN -IsContainerDN
                $item  = & $makeCheckItem "📁 $($ou.Name)" $ou.DN $canon $false
                $nodeMap[$ou.DN.ToUpperInvariant()] = $item

                $commaIdx = $ou.DN.IndexOf(',')
                $parentDN = if ($commaIdx -gt 0) { $ou.DN.Substring($commaIdx + 1) } else { $defaultNC }
                $parentKey = $parentDN.ToUpperInvariant()
                if ($nodeMap.ContainsKey($parentKey)) {
                    [void]$nodeMap[$parentKey].Items.Add($item)
                } else {
                    [void]$rootItem.Items.Add($item)
                }
            }

            [void]$tvPickerOUs.Items.Add($rootItem)
            $lblPickerStatus.Text = "Loaded $($ouList.Count) container(s). Check one or multiple OUs to $($SyncType.ToLowerInvariant())."
        } catch {
            $lblPickerStatus.Text = "Error loading AD OUs: $($_.Exception.Message)"
            [System.Windows.MessageBox]::Show("Failed to load Active Directory OUs:`n`n$($_.Exception.Message)", "AD Connection Error", "OK", "Warning")
        } finally {
            if ($null -ne $ouResults)  { try { $ouResults.Dispose() } catch {} }
            if ($null -ne $ouSearcher) { try { $ouSearcher.Dispose() } catch {} }
            if ($null -ne $rootEntry)  { try { $rootEntry.Dispose() } catch {} }
            if ($null -ne $rootDse)    { try { $rootDse.Dispose() } catch {} }
        }
    }

    $btnPickerConnect.Add_Click($script:LoadAdPickerTree)

    $btnPickerOk.Add_Click({
        $checkedBoxes = @($script:PickerAllCheckBoxes | Where-Object { $_.IsChecked -eq $true })
        if ($checkedBoxes.Count -eq 0 -and $tvPickerOUs.SelectedItem -and $tvPickerOUs.SelectedItem.Tag) {
            # Also allow highlighting a single TreeViewItem and clicking Add
            $tagObj = $tvPickerOUs.SelectedItem.Tag
            $incSub = ($chkPickerSubtree.IsChecked -eq $true)
            $script:PickedAdContainers = @([PSCustomObject]@{
                SyncType          = $SyncType
                IncludedGlyph     = if ($SyncType -eq "Include") { "✔" } else { "✖" }
                IncludeSubtree    = $incSub
                SubtreeGlyph      = if ($incSub) { "✔" } else { "—" }
                CanonicalPath     = "$($tagObj.CanonicalPath)"
                DistinguishedName = "$($tagObj.DistinguishedName)"
                Domain            = "$($tagObj.Domain)"
            })
            $pWin.DialogResult = $true
            $pWin.Close()
            return
        }
        if ($checkedBoxes.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please check one or more OUs / containers in the tree.", "No Containers Checked", "OK", "Information")
            return
        }
        $incSub = ($chkPickerSubtree.IsChecked -eq $true)
        $picked = New-Object System.Collections.Generic.List[PSCustomObject]
        foreach ($cb in $checkedBoxes) {
            $t = $cb.Tag
            # If user deselected any child OU under this parent OU, use OneLevel (IncludeSubtree = $false)
            # on this ancestor OU so deselected child OUs are not synced.
            $nodeIncSub = if ($incSub -and $t.TreeViewItem) {
                (-not (Test-AdPickerHasUncheckedDescendant -Node $t.TreeViewItem))
            } else {
                $incSub
            }
            $picked.Add([PSCustomObject]@{
                SyncType          = $SyncType
                IncludedGlyph     = if ($SyncType -eq "Include") { "✔" } else { "✖" }
                IncludeSubtree    = $nodeIncSub
                SubtreeGlyph      = if ($nodeIncSub) { "✔" } else { "—" }
                CanonicalPath     = "$($t.CanonicalPath)"
                DistinguishedName = "$($t.DistinguishedName)"
                Domain            = "$($t.Domain)"
            })
        }
        $script:PickedAdContainers = $picked.ToArray()
        $pWin.DialogResult = $true
        $pWin.Close()
    })

    $btnPickerCancel.Add_Click({
        $pWin.DialogResult = $false
        $pWin.Close()
    })

    $pWin.Add_ContentRendered({
        if (-not [string]::IsNullOrWhiteSpace($txtPickerDomain.Text) -and $script:LoadAdPickerTree) {
            & $script:LoadAdPickerTree
        }
    })

    if ($pWin.ShowDialog() -eq $true) {
        return $script:PickedAdContainers
    }
    return @()
}

function Show-AdSyncDialog {
    Load-AdSyncConfig

    [xml]$adSyncXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Active Directory Sync — Computer Inventory"
        Width="780" Height="560" MinWidth="680" MinHeight="480"
        ResizeMode="CanResizeWithGrip"
        WindowStartupLocation="CenterOwner"
        Background="#1E1E2E" Foreground="#CDD6F4" FontFamily="Segoe UI" FontSize="12.5">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Opacity" Value="0.9"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="CaretBrush" Value="#89B4FA"/>
            <Setter Property="BorderBrush" Value="#45475A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="6,3"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#89B4FA"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="BorderBrush" Value="#313244"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>
        <Style TargetType="DataGridRow">
            <Setter Property="Background" Value="#1E1E2E"/>
            <Setter Property="Foreground" Value="#CDD6F4"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#2563EB"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <GroupBox Grid.Row="0" Header=" Active Directory Sync " BorderBrush="#45475A" BorderThickness="1" Foreground="#89B4FA" Padding="14,12,14,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="135"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Row 0: Auto Sync Enabled -->
                <CheckBox Grid.Row="0" Grid.Column="1" Name="chkAdSyncAuto" Content="Auto Sync Enabled" Margin="0,2,0,10" FontWeight="SemiBold"/>

                <!-- Row 1: Sync Every d / h / m -->
                <TextBlock Grid.Row="1" Grid.Column="0" Text="Sync Every" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="0,0,0,10"/>
                <StackPanel Grid.Row="1" Grid.Column="1" Orientation="Horizontal" Margin="0,0,0,10">
                    <TextBox Name="txtSyncDays" Width="54" Height="26" Text="0" HorizontalContentAlignment="Right"/>
                    <TextBlock Text=" d   " VerticalAlignment="Center" Foreground="#A6ADC8" Margin="4,0,8,0"/>
                    <TextBox Name="txtSyncHours" Width="54" Height="26" Text="4" HorizontalContentAlignment="Right"/>
                    <TextBlock Text=" h   " VerticalAlignment="Center" Foreground="#A6ADC8" Margin="4,0,8,0"/>
                    <TextBox Name="txtSyncMinutes" Width="54" Height="26" Text="0" HorizontalContentAlignment="Right"/>
                    <TextBlock Text=" m" VerticalAlignment="Center" Foreground="#A6ADC8" Margin="4,0,0,0"/>
                </StackPanel>

                <!-- Row 2: Delete Mode -->
                <TextBlock Grid.Row="2" Grid.Column="0" Text="Delete Mode" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="0,0,0,10"/>
                <ComboBox Grid.Row="2" Grid.Column="1" Name="cmbAdDeleteMode" Height="28" Margin="0,0,0,10" Background="#181825" Foreground="#11111B">
                    <ComboBoxItem Content="Full Sync (delete all computers not part of sync)" Tag="Full Sync"/>
                    <ComboBoxItem Content="Mixed Sync (delete AD-synced computers not part of sync)" Tag="Mixed Sync"/>
                    <ComboBoxItem Content="Import Only (never delete computers)" Tag="Import Only" IsSelected="True"/>
                </ComboBox>

                <!-- Row 3: Sync Disabled Computers -->
                <CheckBox Grid.Row="3" Grid.Column="1" Name="chkSyncDisabledComps" Content="Sync Disabled Computers" Margin="0,0,0,12"/>

                <!-- Row 4: Containers to Sync + Right Action Stack -->
                <TextBlock Grid.Row="4" Grid.Column="0" Text="Containers to Sync" Foreground="#CDD6F4" VerticalAlignment="Top" Margin="0,4,0,0"/>
                <Grid Grid.Row="4" Grid.Column="1" Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="148"/>
                    </Grid.ColumnDefinitions>

                    <DataGrid Grid.Column="0" Name="dgAdSyncContainers" AutoGenerateColumns="False" CanUserAddRows="False"
                              HeadersVisibility="Column" GridLinesVisibility="All" HorizontalGridLinesBrush="#313244" VerticalGridLinesBrush="#313244"
                              Background="#181825" BorderBrush="#45475A" BorderThickness="1" RowHeight="28" SelectionMode="Extended" IsReadOnly="True">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Included" Binding="{Binding IncludedGlyph}" Width="70">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="HorizontalAlignment" Value="Center"/>
                                        <Setter Property="VerticalAlignment" Value="Center"/>
                                        <Setter Property="FontWeight" Value="Bold"/>
                                        <Setter Property="Foreground" Value="#A6E3A1"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Subtree" Binding="{Binding SubtreeGlyph}" Width="65">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="HorizontalAlignment" Value="Center"/>
                                        <Setter Property="VerticalAlignment" Value="Center"/>
                                        <Setter Property="Foreground" Value="#89B4FA"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Container" Binding="{Binding CanonicalPath}" Width="*">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="VerticalAlignment" Value="Center"/>
                                        <Setter Property="Margin" Value="6,0,4,0"/>
                                        <Setter Property="ToolTip" Value="{Binding DistinguishedName}"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                        </DataGrid.Columns>
                    </DataGrid>

                    <Grid Grid.Column="1" Margin="10,0,0,0">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <StackPanel Grid.Row="0" Orientation="Vertical">
                            <Button Name="btnAdIncludeContainer" Content="Include Container" Height="28" Margin="0,0,0,6"/>
                            <Button Name="btnAdExcludeContainer" Content="Exclude Container" Height="28" Margin="0,0,0,6"/>
                            <Button Name="btnAdEditContainer" Content="Edit" Height="28" Margin="0,0,0,12" ToolTip="Toggle Include/Exclude or Subtree scope on selected container"/>
                            <Button Name="btnAdSyncNow" Content="Sync Now" Height="30" Background="#89B4FA" Foreground="#11111B" FontWeight="Bold"/>
                        </StackPanel>
                        <Button Grid.Row="2" Name="btnAdDeleteContainer" Content="Delete" Height="28" Background="#452736" BorderBrush="#F38BA8" Foreground="#F38BA8"/>
                    </Grid>
                </Grid>

                <!-- Row 5: Last Sync -->
                <TextBlock Grid.Row="5" Grid.Column="0" Text="Last Sync" Foreground="#A6ADC8" VerticalAlignment="Center" Margin="0,2,0,6"/>
                <TextBlock Grid.Row="5" Grid.Column="1" Name="lblAdLastSyncTime" Text="Never" Foreground="#CDD6F4" VerticalAlignment="Center" Margin="0,2,0,6"/>

                <!-- Row 6: Last Sync Status -->
                <TextBlock Grid.Row="6" Grid.Column="0" Text="Last Sync Status" Foreground="#A6ADC8" VerticalAlignment="Center"/>
                <TextBlock Grid.Row="6" Grid.Column="1" Name="lblAdLastSyncStatus" Text="Not synced yet" Foreground="#A6E3A1" FontWeight="SemiBold" VerticalAlignment="Center"/>
            </Grid>
        </GroupBox>

        <Grid Grid.Row="1" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button Grid.Column="0" Name="btnAdBrowseIndividual" Content="🔍 Browse Individual Computers..." Height="32" Padding="12,5" ToolTip="Open individual computer browser to pick ad-hoc computers"/>
            <Button Grid.Column="2" Name="btnAdSyncSave" Content="✔ Save" Width="105" Height="32" Background="#A6E3A1" Foreground="#11111B" FontWeight="Bold" Margin="0,0,8,0"/>
            <Button Grid.Column="3" Name="btnAdSyncCancel" Content="Cancel" Width="95" Height="32"/>
        </Grid>
    </Grid>
</Window>
"@

    $sReader = New-Object System.Xml.XmlNodeReader($adSyncXaml)
    $sWin    = [Windows.Markup.XamlReader]::Load($sReader)
    $sWin.Owner = $window

    $chkAdSyncAuto         = $sWin.FindName("chkAdSyncAuto")
    $txtSyncDays           = $sWin.FindName("txtSyncDays")
    $txtSyncHours          = $sWin.FindName("txtSyncHours")
    $txtSyncMinutes        = $sWin.FindName("txtSyncMinutes")
    $cmbAdDeleteMode       = $sWin.FindName("cmbAdDeleteMode")
    $chkSyncDisabledComps  = $sWin.FindName("chkSyncDisabledComps")
    $dgAdSyncContainers    = $sWin.FindName("dgAdSyncContainers")
    $btnAdIncludeContainer = $sWin.FindName("btnAdIncludeContainer")
    $btnAdExcludeContainer = $sWin.FindName("btnAdExcludeContainer")
    $btnAdEditContainer    = $sWin.FindName("btnAdEditContainer")
    $btnAdSyncNow          = $sWin.FindName("btnAdSyncNow")
    $btnAdDeleteContainer  = $sWin.FindName("btnAdDeleteContainer")
    $lblAdLastSyncTime     = $sWin.FindName("lblAdLastSyncTime")
    $lblAdLastSyncStatus   = $sWin.FindName("lblAdLastSyncStatus")
    $btnAdBrowseIndividual = $sWin.FindName("btnAdBrowseIndividual")
    $btnAdSyncSave         = $sWin.FindName("btnAdSyncSave")
    $btnAdSyncCancel       = $sWin.FindName("btnAdSyncCancel")

    $chkAdSyncAuto.IsChecked        = [bool]$script:AdSyncConfig.AutoSyncEnabled
    $txtSyncDays.Text               = "$($script:AdSyncConfig.SyncDays)"
    $txtSyncHours.Text              = "$($script:AdSyncConfig.SyncHours)"
    $txtSyncMinutes.Text            = "$($script:AdSyncConfig.SyncMinutes)"
    $chkSyncDisabledComps.IsChecked = [bool]$script:AdSyncConfig.SyncDisabledComputers
    $lblAdLastSyncTime.Text         = "$($script:AdSyncConfig.LastSyncTime)"
    $lblAdLastSyncStatus.Text       = "$($script:AdSyncConfig.LastSyncStatus)"

    foreach ($cbi in $cmbAdDeleteMode.Items) {
        if ("$($cbi.Tag)" -eq "$($script:AdSyncConfig.DeleteMode)") {
            $cmbAdDeleteMode.SelectedItem = $cbi
            break
        }
    }

    $containersObs = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
    foreach ($c in @($script:AdSyncConfig.Containers)) {
        $containersObs.Add([PSCustomObject]@{
            SyncType          = "$($c.SyncType)"
            IncludedGlyph     = if ($c.SyncType -eq "Exclude") { "✖" } else { "✔" }
            IncludeSubtree    = [bool]$c.IncludeSubtree
            SubtreeGlyph      = if ($c.IncludeSubtree) { "✔" } else { "—" }
            CanonicalPath     = "$($c.CanonicalPath)"
            DistinguishedName = "$($c.DistinguishedName)"
            Domain            = "$($c.Domain)"
        })
    }
    $dgAdSyncContainers.ItemsSource = $containersObs

    $script:ApplyAdSyncDialogToConfig = {
        $dVal = 0; [void][int]::TryParse($txtSyncDays.Text.Trim(), [ref]$dVal)
        $hVal = 4; [void][int]::TryParse($txtSyncHours.Text.Trim(), [ref]$hVal)
        $mVal = 0; [void][int]::TryParse($txtSyncMinutes.Text.Trim(), [ref]$mVal)
        $selDel = if ($cmbAdDeleteMode.SelectedItem -and $cmbAdDeleteMode.SelectedItem.Tag) {
            "$($cmbAdDeleteMode.SelectedItem.Tag)"
        } else { "Import Only" }

        $script:AdSyncConfig.AutoSyncEnabled       = ($chkAdSyncAuto.IsChecked -eq $true)
        $script:AdSyncConfig.SyncDays              = [Math]::Max(0, $dVal)
        $script:AdSyncConfig.SyncHours             = [Math]::Max(0, $hVal)
        $script:AdSyncConfig.SyncMinutes           = [Math]::Max(0, $mVal)
        $script:AdSyncConfig.DeleteMode            = $selDel
        $script:AdSyncConfig.SyncDisabledComputers = ($chkSyncDisabledComps.IsChecked -eq $true)
        $script:AdSyncConfig.Containers            = @($containersObs)
        Save-AdSyncConfig
        Update-AdAutoSyncTimer
    }

    $script:AddPickedAdContainers = {
        param([string]$Mode)
        $picked = @(Select-AdContainersDialog -SyncType $Mode -InitialDomain $script:AdSyncConfig.Domain)
        foreach ($p in $picked) {
            if (-not $p -or [string]::IsNullOrWhiteSpace($p.DistinguishedName)) { continue }
            if (-not [string]::IsNullOrWhiteSpace($p.Domain)) {
                $script:AdSyncConfig.Domain = $p.Domain
            }
            $existing = $containersObs | Where-Object { $_.DistinguishedName -ieq $p.DistinguishedName } | Select-Object -First 1
            if ($existing) {
                $existing.SyncType       = $p.SyncType
                $existing.IncludedGlyph  = $p.IncludedGlyph
                $existing.IncludeSubtree = $p.IncludeSubtree
                $existing.SubtreeGlyph   = $p.SubtreeGlyph
            } else {
                $containersObs.Add($p)
            }
        }
        $dgAdSyncContainers.Items.Refresh()
    }

    $btnAdIncludeContainer.Add_Click({ if ($script:AddPickedAdContainers) { & $script:AddPickedAdContainers "Include" } })
    $btnAdExcludeContainer.Add_Click({ if ($script:AddPickedAdContainers) { & $script:AddPickedAdContainers "Exclude" } })

    $btnAdEditContainer.Add_Click({
        $sel = $dgAdSyncContainers.SelectedItem
        if (-not $sel) {
            [System.Windows.MessageBox]::Show("Select a container row in the list to toggle its Include/Exclude or Subtree setting.", "Edit Container", "OK", "Information")
            return
        }
        $sel.IncludeSubtree = -not [bool]$sel.IncludeSubtree
        $sel.SubtreeGlyph   = if ($sel.IncludeSubtree) { "✔" } else { "—" }
        $dgAdSyncContainers.Items.Refresh()
    })

    $dgAdSyncContainers.Add_MouseDoubleClick({
        $sel = $dgAdSyncContainers.SelectedItem
        if ($sel) {
            $sel.SyncType      = if ($sel.SyncType -eq "Exclude") { "Include" } else { "Exclude" }
            $sel.IncludedGlyph = if ($sel.SyncType -eq "Exclude") { "✖" } else { "✔" }
            $dgAdSyncContainers.Items.Refresh()
        }
    })

    $btnAdDeleteContainer.Add_Click({
        $selItems = @($dgAdSyncContainers.SelectedItems)
        if ($selItems.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Select one or more containers in the list to remove.", "Delete Container", "OK", "Information")
            return
        }
        foreach ($s in $selItems) {
            [void]$containersObs.Remove($s)
        }
    })

    $btnAdSyncNow.Add_Click({
        if ($script:ApplyAdSyncDialogToConfig) { & $script:ApplyAdSyncDialogToConfig }
        [void](Invoke-AdSync)
        $lblAdLastSyncTime.Text   = "$($script:AdSyncConfig.LastSyncTime)"
        $lblAdLastSyncStatus.Text = "$($script:AdSyncConfig.LastSyncStatus)"
    })

    $btnAdBrowseIndividual.Add_Click({
        if ($script:ApplyAdSyncDialogToConfig) { & $script:ApplyAdSyncDialogToConfig }
        $sWin.Close()
        Show-ActiveDirectoryImportDialog
    })

    $btnAdSyncSave.Add_Click({
        if ($script:ApplyAdSyncDialogToConfig) { & $script:ApplyAdSyncDialogToConfig }
        if ($containersObs.Count -gt 0 -and $script:AdSyncConfig.LastSyncTime -eq "Never") {
            [void](Invoke-AdSync)
        }
        $sWin.Close()
    })

    $btnAdSyncCancel.Add_Click({
        $sWin.Close()
    })

    [void]$sWin.ShowDialog()
}

$btnBrowseAD.Add_Click({
    Show-AdSyncDialog
})

$btnRefreshTargets.Add_Click({
    if ($script:TargetsCollection.Count -eq 0) { return }
    Start-BackgroundTargetProbe -TargetsToProbe @($script:TargetsCollection)
})

$btnSelectAllTargets.Add_Click({
    if ($script:TargetsCollection.Count -eq 0) { return }
    try {
        [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
        [void]$dgTargets.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true)
    } catch {}

    if (Test-TargetFilterActive) {
        $visibleRows = @($script:TargetsCollection | Where-Object { Test-TargetItemFilter -Item $_ })
        $visibleSet = [System.Collections.Generic.HashSet[object]]::new()
        foreach ($vr in $visibleRows) {
            [void]$visibleSet.Add($vr)
        }
        $hadHiddenSelected = $false
        foreach ($item in $script:TargetsCollection) {
            if (-not $visibleSet.Contains($item)) {
                if ([bool]$item.Selected) { $hadHiddenSelected = $true }
                $item.Selected = $false
            }
        }
        if ($visibleRows.Count -eq 0) {
            Invoke-RefreshTargetsFilter
            return
        }
        $anyVisibleUnselected = ($visibleRows | Where-Object { -not [bool]$_.Selected }).Count -gt 0
        # If any visible row is unchecked, or if hidden rows were selected while filtering, check ONLY the visible filtered rows
        $newState = if ($anyVisibleUnselected -or $hadHiddenSelected) { $true } else { $false }
        foreach ($t in $visibleRows) {
            $t.Selected = $newState
        }
    } else {
        $anyUnselected = ($script:TargetsCollection | Where-Object { -not [bool]$_.Selected }).Count -gt 0
        foreach ($t in $script:TargetsCollection) {
            $t.Selected = $anyUnselected
        }
    }
    Invoke-RefreshTargetsFilter
})

$btnRemoveTarget.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel) {
        [void]$script:TargetsCollection.Remove($sel)
        Update-TargetCountSummary
        Save-ComputerInventory
    } else {
        [System.Windows.MessageBox]::Show("Select a row in the Computer Inventory table to remove.", "Remove Computer", "OK", "Information")
    }
})

# Windows 11 Right-Click ContextMenu on Target Computers DataGrid
$ctxTargets = New-Win11ContextMenu
$targetQuickBarHost = New-Object System.Windows.Controls.MenuItem
$targetQuickBarHost.StaysOpenOnClick = $true
$targetQuickBarHost.Padding = New-Object System.Windows.Thickness(2, 2, 2, 2)

$targetQuickPanel = New-Object System.Windows.Controls.StackPanel
$targetQuickPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$targetQuickPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

$btnQTgtToggle = New-Win11QuickActionButton -Glyph "☑" -Label "Toggle" -GlyphColor "#89B4FA" -ToolTipText "Toggle Deploy checkbox on selected computer"
$btnQTgtToggle.Tag = $ctxTargets
$btnQTgtToggle.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgTargets.SelectedItem
    if ($sel -and $null -ne $sel.PSObject.Properties['Selected']) {
        $sel.Selected = -not [bool]$sel.Selected
        Invoke-RefreshTargetsFilter
    }
})
[void]$targetQuickPanel.Children.Add($btnQTgtToggle)

$btnQTgtProbe = New-Win11QuickActionButton -Glyph "🔄" -Label "Probe" -GlyphColor "#A6E3A1" -ToolTipText "Probe online status of selected computer"
$btnQTgtProbe.Tag = $ctxTargets
$btnQTgtProbe.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgTargets.SelectedItem
    if ($sel) { Start-BackgroundTargetProbe -TargetsToProbe @($sel) }
})
[void]$targetQuickPanel.Children.Add($btnQTgtProbe)

$btnQTgtCopy = New-Win11QuickActionButton -Glyph "📋" -Label "Copy" -GlyphColor "#CBA6F7" -ToolTipText "Copy Computer Name to clipboard"
$btnQTgtCopy.Tag = $ctxTargets
$btnQTgtCopy.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgTargets.SelectedItem
    if ($sel -and $sel.ComputerName) {
        [System.Windows.Clipboard]::SetText("$($sel.ComputerName)")
        $lblStatus.Text = "Copied computer name '$($sel.ComputerName)' to clipboard."
    }
})
[void]$targetQuickPanel.Children.Add($btnQTgtCopy)

$btnQTgtRemove = New-Win11QuickActionButton -Glyph "✕" -Label "Remove" -GlyphColor "#F38BA8" -ToolTipText "Remove selected computer from target list"
$btnQTgtRemove.Tag = $ctxTargets
$btnQTgtRemove.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgTargets.SelectedItem
    if ($sel) {
        [void]$script:TargetsCollection.Remove($sel)
        Update-TargetCountSummary
    }
})
[void]$targetQuickPanel.Children.Add($btnQTgtRemove)

$targetQuickBarHost.Header = $targetQuickPanel
[void]$ctxTargets.Items.Add($targetQuickBarHost)
[void]$ctxTargets.Items.Add((New-Object System.Windows.Controls.Separator))

$miTgtToggle = New-Object System.Windows.Controls.MenuItem
$miTgtToggle.Header = "Toggle Deploy Check"
$miTgtToggle.InputGestureText = "Space"
$miTgtToggle.Icon = New-Win11MenuIcon -Glyph "☑" -ColorHex "#89B4FA"
$miTgtToggle.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel -and $null -ne $sel.PSObject.Properties['Selected']) {
        $sel.Selected = -not [bool]$sel.Selected
        Invoke-RefreshTargetsFilter
    }
})
[void]$ctxTargets.Items.Add($miTgtToggle)

$miTgtProbeOne = New-Object System.Windows.Controls.MenuItem
$miTgtProbeOne.Header = "Probe Selected Computer Status"
$miTgtProbeOne.InputGestureText = "F5"
$miTgtProbeOne.Icon = New-Win11MenuIcon -Glyph "🔄" -ColorHex "#A6E3A1"
$miTgtProbeOne.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel) { Start-BackgroundTargetProbe -TargetsToProbe @($sel) }
})
[void]$ctxTargets.Items.Add($miTgtProbeOne)

$miTgtDeployNow = New-Object System.Windows.Controls.MenuItem
$miTgtDeployNow.Header = "Deploy Current Package to Selected Computer"
$miTgtDeployNow.InputGestureText = "Run"
$miTgtDeployNow.Icon = New-Win11MenuIcon -Glyph "🚀" -ColorHex "#A6E3A1"
$miTgtDeployNow.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel -and $sel.ComputerName) {
        Invoke-DeploymentForTargets -TargetComputers @($sel.ComputerName) -StartStepIndex 0
    }
})
[void]$ctxTargets.Items.Add($miTgtDeployNow)

[void]$ctxTargets.Items.Add((New-Object System.Windows.Controls.Separator))

$miTgtCopyName = New-Object System.Windows.Controls.MenuItem
$miTgtCopyName.Header = "Copy Computer Name"
$miTgtCopyName.InputGestureText = "Ctrl+C"
$miTgtCopyName.Icon = New-Win11MenuIcon -Glyph "📋" -ColorHex "#CBA6F7"
$miTgtCopyName.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel -and $sel.ComputerName) {
        [System.Windows.Clipboard]::SetText("$($sel.ComputerName)")
        $lblStatus.Text = "Copied computer name '$($sel.ComputerName)' to clipboard."
    }
})
[void]$ctxTargets.Items.Add($miTgtCopyName)

$miTgtCopyIP = New-Object System.Windows.Controls.MenuItem
$miTgtCopyIP.Header = "Copy IP Address"
$miTgtCopyIP.InputGestureText = "IP"
$miTgtCopyIP.Icon = New-Win11MenuIcon -Glyph "🌐" -ColorHex "#89DCEB"
$miTgtCopyIP.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel -and $sel.IPAddress) {
        [System.Windows.Clipboard]::SetText("$($sel.IPAddress)")
        $lblStatus.Text = "Copied IP address '$($sel.IPAddress)' to clipboard."
    }
})
[void]$ctxTargets.Items.Add($miTgtCopyIP)

[void]$ctxTargets.Items.Add((New-Object System.Windows.Controls.Separator))

$miTgtSelectAll = New-Object System.Windows.Controls.MenuItem
$miTgtSelectAll.Header = "Toggle Check All / None"
$miTgtSelectAll.InputGestureText = "Ctrl+A"
$miTgtSelectAll.Icon = New-Win11MenuIcon -Glyph "✔" -ColorHex "#89B4FA"
$miTgtSelectAll.Add_Click({
    $btnSelectAllTargets.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
})
[void]$ctxTargets.Items.Add($miTgtSelectAll)

$miTgtClearFilters = New-Object System.Windows.Controls.MenuItem
$miTgtClearFilters.Header = "Clear All Target Filters"
$miTgtClearFilters.InputGestureText = "Reset"
$miTgtClearFilters.Icon = New-Win11MenuIcon -Glyph "🧹" -ColorHex "#F9E2AF"
$miTgtClearFilters.Add_Click({
    Clear-AllTargetColumnFilters
})
[void]$ctxTargets.Items.Add($miTgtClearFilters)

[void]$ctxTargets.Items.Add((New-Object System.Windows.Controls.Separator))

$miTgtRemove = New-Object System.Windows.Controls.MenuItem
$miTgtRemove.Header = "Remove Selected Computer"
$miTgtRemove.InputGestureText = "Del"
$miTgtRemove.Icon = New-Win11MenuIcon -Glyph "✕" -ColorHex "#F38BA8"
$miTgtRemove.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F38BA8")
$miTgtRemove.Add_Click({
    $sel = $dgTargets.SelectedItem
    if ($sel) {
        [void]$script:TargetsCollection.Remove($sel)
        Update-TargetCountSummary
    }
})
[void]$ctxTargets.Items.Add($miTgtRemove)
$dgTargets.ContextMenu = $ctxTargets

# ==========================================
# 6. CREDENTIALS & WINRM PREFLIGHT
# ==========================================
function Get-TargetCredential {
    param(
        [string]$TargetComputer,
        [string]$DomainInput,
        [string]$UserInput,
        [System.Security.SecureString]$SecurePassword
    )

    $hasSlash = $UserInput -match '[\\/]'
    $hasAt    = $UserInput -match '@'

    $finalUser = $UserInput
    $credKind  = 'Bare'

    if ($hasSlash -or $hasAt) {
        $finalUser = $UserInput
        $credKind  = if ($hasSlash -and ($UserInput -match '^(?<prefix>[^\\]+)\\(?<subuser>.+)$') -and $Matches['prefix'] -match '^(localhost|127\.0\.0\.1|\.)$') {
            "$TargetComputer\$($Matches['subuser'])"
            'Local'
        } else {
            'Domain'
        }
        if ($credKind -eq 'Local') {
            $finalUser = "$TargetComputer\$($Matches['subuser'])"
        }
    } else {
        if (-not [string]::IsNullOrWhiteSpace($DomainInput)) {
            $d = $DomainInput.Trim()
            if ($d -match '^(localhost|127\.0\.0\.1|\.)$') {
                $finalUser = "$TargetComputer\$UserInput"
                $credKind  = 'Local'
            } else {
                $finalUser = "$d\$UserInput"
                $credKind  = 'Domain'
            }
        } else {
            $finalUser = $UserInput
            $credKind  = 'Bare'
        }
    }

    $cred = if ($null -ne $SecurePassword -and $SecurePassword.Length -gt 0) {
        New-Object System.Management.Automation.PSCredential($finalUser, $SecurePassword)
    } else {
        $null
    }

    return @{
        Credential = $cred
        CredKind   = $credKind
        UserString = $finalUser
    }
}

function Get-WinRMHint {
    param(
        [string]$Message,
        [string]$CredKind
    )
    if ($Message -match '0x803380E4' -or $Message -match '0x803381A4' -or $Message -match 'Access is denied' -or $Message -match 'Logon failure') {
        if ($CredKind -eq 'Local') {
            return "[HINT: Target may need LocalAccountTokenFilterPolicy=1 to allow local admin over WinRM. Run on target: reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f] "
        } else {
            return "[HINT: Check domain admin credentials and verify account is not locked out.] "
        }
    }
    if ($Message -match '0x803380AB' -or $Message -match 'Cannot connect to the destination' -or $Message -match 'destination computer.*is not responding') {
        return "[HINT: Verify WinRM is running on target and TCP port 5985 is open: Test-NetConnection -ComputerName <target> -Port 5985. Run on target: winrm quickconfig] "
    }
    if ($Message -match 'The WinRM client cannot process the request' -and $Message -match 'authentication') {
        return "[HINT: Target hostname/IP may need to be in TrustedHosts on this machine: Set-Item WSMan:\localhost\Client\TrustedHosts -Value '<target>' -Concatenate -Force] "
    }
    return ""
}

function Test-TrustedHostMatch {
    param(
        [string]$Target,
        [string[]]$Entries
    )
    if ($Entries -contains '*') { return $true }
    foreach ($e in $Entries) {
        if ($e -ieq $Target) { return $true }
        if ($e -like '*.*' -and $e.StartsWith('*.')) {
            $suffix = $e.Substring(1)
            if ($Target.EndsWith($suffix, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        }
    }
    return $false
}

function Test-IsLocalComputer {
    param([string]$ComputerName)
    if ([string]::IsNullOrWhiteSpace($ComputerName)) { return $false }
    $clean = $ComputerName.Trim()
    if ($clean -in @('localhost', '127.0.0.1', '::1', '.')) { return $true }
    $short = ($clean -split '\.')[0]
    if ($short -ieq $env:COMPUTERNAME -or $short -ieq [System.Environment]::MachineName) { return $true }
    try {
        $dnsHost = [System.Net.Dns]::GetHostName()
        if ($clean -ieq $dnsHost -or $short -ieq ($dnsHost -split '\.')[0]) { return $true }
    } catch {}
    try {
        foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            foreach ($ua in $ni.GetIPProperties().UnicastAddresses) {
                if ($ua.Address -and $ua.Address.IPAddressToString -ieq $clean) { return $true }
            }
        }
    } catch {}
    return $false
}

function Get-MissingTrustedHosts {
    param(
        [string[]]$TargetList,
        [string]$Kind
    )
    $entries = @()
    try {
        $val = (Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction Stop).Value
        if (-not [string]::IsNullOrWhiteSpace($val)) {
            $entries = @($val -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
    } catch { $entries = @() }

    $missing = @()
    foreach ($t in $TargetList) {
        if (Test-IsLocalComputer -ComputerName $t) { continue }
        $isIP = ($t -match '^\d{1,3}(\.\d{1,3}){3}$') -or ($t -match ':')
        $needs = $isIP -or ($Kind -eq 'Local') -or ($Kind -eq 'Bare')
        if ($needs -and -not (Test-TrustedHostMatch $t $entries)) {
            $missing += $t
        }
    }
    return $missing
}

function Add-TrustedHostsElevated {
    param([string[]]$HostsToAdd)
    $current = ''
    try { $current = (Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction Stop).Value } catch {}
    $list = @()
    if (-not [string]::IsNullOrWhiteSpace($current)) {
        $list += @($current -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    foreach ($h in $HostsToAdd) { if ($list -notcontains $h) { $list += $h } }
    $value = ($list -join ',') -replace "'", ''
    $payload = "Start-Service WinRM -ErrorAction SilentlyContinue; Set-Item WSMan:\localhost\Client\TrustedHosts -Value '$value' -Force"
    try {
        $proc = Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$payload`"" -Wait -PassThru -ErrorAction Stop
        return ($proc.ExitCode -eq 0)
    } catch {
        return $false
    }
}

function Test-TargetReachable {
    param(
        [string]$ComputerName,
        [int]$TimeoutMs = 2500
    )

    if (Test-IsLocalComputer -ComputerName $ComputerName) {
        return $true
    }

    # 1. Test TCP WinRM HTTP (5985) and HTTPS (5986)
    foreach ($port in @(5985, 5986)) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect($ComputerName, $port, $null, $null)
            $waitSuccess = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
            if ($waitSuccess -and $tcpClient.Connected) {
                $tcpClient.EndConnect($asyncResult)
                $tcpClient.Close()
                return $true
            }
            $tcpClient.Close()
        } catch {}
    }

    # 2. Fall back to ICMP Echo ping
    try {
        if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            return $true
        }
    } catch {}

    return $false
}

# ==========================================
# 7. ROBUST REMOTE EXECUTION ENGINE
# ==========================================
$stepRunner = {
    param(
        [string]$ScriptText,
        [string]$ScriptParameters = "",
        [string]$RemoteStagingDir = "C:\Temp\PSDeploy",
        [int]$StepOrder = 1,
        [string]$StepName = "Step",
        [string]$StepType = "PowerShell",
        [string]$PayloadFileName = "",
        [bool]$SilentInstall = $true
    )
    
    $ConfirmPreference = 'None'
    $ProgressPreference = 'SilentlyContinue'

    # Ensure remote staging directory exists
    $targetDir = $RemoteStagingDir
    if ([string]::IsNullOrWhiteSpace($targetDir)) {
        $targetDir = "C:\Temp\PSDeploy"
    }
    try {
        if (-not [System.IO.Directory]::Exists($targetDir)) {
            [void][System.IO.Directory]::CreateDirectory($targetDir)
        }
    } catch {
        $targetDir = [System.IO.Path]::GetTempPath()
    }

    $safeName = ($StepName -replace '[\\/:*?"<>| ]', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = "Step$StepOrder" }
    if ($safeName.Length -gt 30) { $safeName = $safeName.Substring(0, 30) }

    $tempScript = $null
    $stdOutLines = [System.Collections.Generic.List[string]]::new()
    $stdErrText  = ""
    $exitCode    = -1
    $remoteLogFile = $null

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.WorkingDirectory = $targetDir
        $psi.EnvironmentVariables["PSDEPLOY_STAGING_DIR"] = $targetDir
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardInput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        if ($StepType -eq 'Batch') {
            # Write batch file using ASCII / UTF8 without BOM
            $tempScript = [System.IO.Path]::Combine($targetDir, "Deploy_Step_${StepOrder}_$([System.Guid]::NewGuid().ToString('N')).bat")
            [System.IO.File]::WriteAllText($tempScript, $ScriptText, [System.Text.Encoding]::ASCII)

            $psi.FileName = "cmd.exe"
            $arguments = "/d /c `"`"$tempScript`""
            if (-not [string]::IsNullOrWhiteSpace($ScriptParameters)) {
                $arguments += " $ScriptParameters"
            }
            $arguments += "`""
            $psi.Arguments = $arguments

        } elseif ($StepType -eq 'Installer') {
            # Resolve payload location on target
            $targetPayload = [System.IO.Path]::Combine($targetDir, "Step_$StepOrder", $PayloadFileName)
            if (-not [System.IO.File]::Exists($targetPayload)) {
                $targetPayload = [System.IO.Path]::Combine($targetDir, $PayloadFileName)
            }
            if (-not [System.IO.File]::Exists($targetPayload)) {
                $targetPayload = $PayloadFileName
            }

            $ext = [System.IO.Path]::GetExtension($targetPayload).ToLower()
            switch ($ext) {
                ".msi" {
                    $psi.FileName = "msiexec.exe"
                    $psi.Arguments = "/i `"$targetPayload`" $($ScriptParameters.Trim())"
                }
                ".msp" {
                    $psi.FileName = "msiexec.exe"
                    $psi.Arguments = "/p `"$targetPayload`" $($ScriptParameters.Trim())"
                }
                ".msu" {
                    $psi.FileName = "wusa.exe"
                    $psi.Arguments = "`"$targetPayload`" $($ScriptParameters.Trim())"
                }
                ".bat" {
                    $psi.FileName = "cmd.exe"
                    $psi.Arguments = "/d /c `"`"$targetPayload`" $ScriptParameters`""
                }
                ".cmd" {
                    $psi.FileName = "cmd.exe"
                    $psi.Arguments = "/d /c `"`"$targetPayload`" $ScriptParameters`""
                }
                ".ps1" {
                    $psi.FileName = "powershell.exe"
                    $psi.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$targetPayload`" $ScriptParameters"
                }
                default {
                    # Direct executable setup (e.g. .exe)
                    $psi.FileName = $targetPayload
                    $psi.Arguments = $ScriptParameters
                }
            }

        } else {
            # Default: PowerShell
            $tempScript = [System.IO.Path]::Combine($targetDir, "Deploy_Step_${StepOrder}_$([System.Guid]::NewGuid().ToString('N')).ps1")
            [System.IO.File]::WriteAllText($tempScript, $ScriptText, [System.Text.Encoding]::UTF8)

            $psi.FileName = "powershell.exe"
            $arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$tempScript`""
            if (-not [string]::IsNullOrWhiteSpace($ScriptParameters)) {
                $arguments += " $ScriptParameters"
            }
            $psi.Arguments = $arguments
        }

        $process = [System.Diagnostics.Process]::Start($psi)
        try { $process.StandardInput.Close() } catch {}
        $errTask = $process.StandardError.ReadToEndAsync()

        $activeReadTask = $null
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $lastPulse = 0

        while (-not $process.HasExited) {
            if ($null -eq $activeReadTask) {
                $activeReadTask = $process.StandardOutput.ReadLineAsync()
            }
            if ($activeReadTask.Wait(200)) {
                $line = $activeReadTask.Result
                $activeReadTask = $null
                if ($null -ne $line) {
                    $cleanLine = $line.TrimEnd("`r", "`n")
                    $stdOutLines.Add($cleanLine)
                    $trimmed = $cleanLine.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                        [PSCustomObject]@{
                            IsLiveProgress = $true
                            Line           = $trimmed
                        }
                    }
                }
            }

            # Periodic status pulse for quiet installers
            if ($timer.Elapsed.TotalSeconds - $lastPulse -gt 3.0) {
                $lastPulse = [int]$timer.Elapsed.TotalSeconds
                if ($StepType -eq 'Installer') {
                    [PSCustomObject]@{
                        IsLiveProgress = $true
                        Line           = "Running payload $([System.IO.Path]::GetFileName($PayloadFileName))... ($([int]$timer.Elapsed.TotalSeconds)s elapsed)"
                    }
                }
            }
        }

        # Drain any remaining active read task
        if ($null -ne $activeReadTask) {
            if ($activeReadTask.Wait(1000)) {
                $line = $activeReadTask.Result
                if ($null -ne $line) {
                    $cleanLine = $line.TrimEnd("`r", "`n")
                    $stdOutLines.Add($cleanLine)
                    $trimmed = $cleanLine.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                        [PSCustomObject]@{
                            IsLiveProgress = $true
                            Line           = $trimmed
                        }
                    }
                }
            }
        }

        # Drain any remaining lines from StandardOutput
        while (-not $process.StandardOutput.EndOfStream) {
            $line = $process.StandardOutput.ReadLine()
            if ($null -ne $line) {
                $cleanLine = $line.TrimEnd("`r", "`n")
                $stdOutLines.Add($cleanLine)
                $trimmed = $cleanLine.Trim()
                if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                    [PSCustomObject]@{
                        IsLiveProgress = $true
                        Line           = $trimmed
                    }
                }
            }
        }

        $process.WaitForExit()
        $exitCode = $process.ExitCode
        if ($errTask.Wait(2000)) {
            $stdErrText = $errTask.Result
        }

        # Treat exit code 0 and 3010 (Reboot Required) as success
        $isSuccess = ($exitCode -eq 0 -or $exitCode -eq 3010)

        # Preserve full multi-line output; only collapse intermediate lines that literally start with '[LIVE]'
        $liveLines   = @($stdOutLines | Where-Object { $_.TrimStart().StartsWith('[LIVE]', [System.StringComparison]::OrdinalIgnoreCase) })
        $normalLines = @($stdOutLines | Where-Object { -not $_.TrimStart().StartsWith('[LIVE]', [System.StringComparison]::OrdinalIgnoreCase) })
        $outputLines = [System.Collections.Generic.List[string]]::new()
        foreach ($nl in $normalLines) { $outputLines.Add($nl) }
        if ($liveLines.Count -gt 0) {
            $outputLines.Add($liveLines[$liveLines.Count - 1])
        }
        $finalMessage = if ($outputLines.Count -gt 0) { ($outputLines -join "`r`n").Trim("`r", "`n") } else { "" }

        if ($isSuccess) {
            if ($exitCode -eq 3010) {
                $finalMessage = "Success — Exit Code 3010: Reboot Required"
            } elseif ([string]::IsNullOrWhiteSpace($finalMessage)) {
                $finalMessage = "(Success — Exit Code 0)"
            }
        } else {
            if (-not [string]::IsNullOrWhiteSpace($stdErrText)) {
                $finalMessage = "Exit Code $($exitCode): $($stdErrText.Trim())"
            } elseif (-not [string]::IsNullOrWhiteSpace($finalMessage)) {
                $finalMessage = "Exit Code $($exitCode): $finalMessage"
            } else {
                $finalMessage = "Execution terminated with non-zero Exit Code $($exitCode)."
            }
        }

        # Write remote execution log file in staging directory
        try {
            $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
            $logFileName = "{0}_Step{1}_{2}_{3}.log" -f $env:COMPUTERNAME, $StepOrder, $safeName, $timestamp
            $remoteLogFile = [System.IO.Path]::Combine($targetDir, $logFileName)
            $logContent = New-Object System.Text.StringBuilder
            [void]$logContent.AppendLine("=== PSDeploy Remote Step Execution Log ===")
            [void]$logContent.AppendLine("ComputerName:  $env:COMPUTERNAME")
            [void]$logContent.AppendLine("Timestamp:     $((Get-Date).ToString('o'))")
            [void]$logContent.AppendLine("Step Order:    $StepOrder")
            [void]$logContent.AppendLine("Step Name:     $StepName")
            [void]$logContent.AppendLine("Step Type:     $StepType")
            [void]$logContent.AppendLine("Arguments:     $ScriptParameters")
            [void]$logContent.AppendLine("Exit Code:     $exitCode")
            [void]$logContent.AppendLine("Result:        $(if ($isSuccess) { 'SUCCESS' } else { 'FAILED' })")
            [void]$logContent.AppendLine("--- Standard Output ---")
            foreach ($l in $stdOutLines) { [void]$logContent.AppendLine($l) }
            if (-not [string]::IsNullOrWhiteSpace($stdErrText)) {
                [void]$logContent.AppendLine("--- Standard Error ---")
                [void]$logContent.AppendLine($stdErrText.Trim())
            }
            [System.IO.File]::WriteAllText($remoteLogFile, $logContent.ToString(), [System.Text.Encoding]::UTF8)
        } catch {}

        return [PSCustomObject]@{
            IsLiveProgress = $false
            Success        = $isSuccess
            ExitCode       = $exitCode
            Message        = $finalMessage
            LogFile        = $remoteLogFile
        }
    }
    catch {
        return [PSCustomObject]@{
            IsLiveProgress = $false
            Success        = $false
            ExitCode       = -999
            Message        = "Process invocation exception: $($_.Exception.Message)"
            LogFile        = $null
        }
    }
    finally {
        if ($tempScript -and [System.IO.File]::Exists($tempScript)) {
            try { [System.IO.File]::Delete($tempScript) } catch {}
        }
    }
}

# ==========================================
# 8. PERSISTENT STATUS & RESULTS ENGINE
# ==========================================
$script:StatusStateFilePath = Join-Path $script:SettingsDir "status_state.json"

function Save-PersistentStatusState {
    try {
        $deployRuns = @($script:DeployPackagesCollection | ForEach-Object {
            [PSCustomObject]@{
                DeploymentId    = [string]$_.DeploymentId
                PackageName     = [string]$_.PackageName
                Status          = if ($_.Status -eq "Running") { "Stopped" } else { [string]$_.Status }
                TargetCount     = [int]$_.TargetCount
                CompletedCount  = [int]$_.CompletedCount
                SuccessCount    = [int]$_.SuccessCount
                FailedCount     = [int]$_.FailedCount
                StoppedCount    = [int]$_.StoppedCount
                TargetSummary   = [string]$_.TargetSummary
                StepsCount      = [int]$_.StepsCount
                StartTime       = [string]$_.StartTime
                EndTime         = [string]$_.EndTime
                Duration        = [string]$_.Duration
                DurationSeconds = [double]$_.DurationSeconds
                TargetComputers = if ($_.PSObject.Properties['TargetComputers'] -and $_.TargetComputers) { @($_.TargetComputers | ForEach-Object { [string]$_ }) } else { @() }
                PackageSteps    = if ($_.PSObject.Properties['PackageSteps'] -and $_.PackageSteps) { @($_.PackageSteps) } else { @() }
            }
        })
        $rows = @($script:ResultsCollection | ForEach-Object {
            [PSCustomObject]@{
                DeploymentId    = if ($_.PSObject.Properties['DeploymentId']) { [string]$_.DeploymentId } else { "" }
                ComputerName    = $_.ComputerName
                PackageName     = if ($_.PSObject.Properties['PackageName'] -and -not [string]::IsNullOrWhiteSpace($_.PackageName)) { $_.PackageName } else { "(Custom Package)" }
                Status          = $_.Status
                Step            = $_.Step
                Details         = $_.Details
                StartTime       = if ($_.PSObject.Properties['StartTime'] -and -not [string]::IsNullOrWhiteSpace($_.StartTime)) { $_.StartTime } else { $_.Timestamp }
                EndTime         = if ($_.PSObject.Properties['EndTime'] -and -not [string]::IsNullOrWhiteSpace($_.EndTime)) { $_.EndTime } else { $_.Timestamp }
                Duration        = $_.Duration
                Timestamp       = $_.Timestamp
                DurationSeconds = $_.DurationSeconds
                FailedStepIndex = $_.FailedStepIndex
                StepHistory     = @($_.StepHistory | ForEach-Object {
                    [PSCustomObject]@{
                        StepIndex = $_.StepIndex
                        StepOrder = $_.StepOrder
                        StepName  = $_.StepName
                        StepType  = $_.StepType
                        Status    = $_.Status
                        Duration  = $_.Duration
                        Seconds   = $_.Seconds
                        Details   = $_.Details
                    }
                })
            }
        })
        $payload = [PSCustomObject]@{
            DeploymentRuns = $deployRuns
            Rows           = $rows
        }
        $json = ConvertTo-Json -InputObject $payload -Depth 6
        [System.IO.File]::WriteAllText($script:StatusStateFilePath, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

function Load-PersistentStatusState {
    if (-not (Test-Path $script:StatusStateFilePath)) { return }
    try {
        $json = [System.IO.File]::ReadAllText($script:StatusStateFilePath, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($json)) { return }
        $raw = ConvertFrom-Json -InputObject $json -ErrorAction Stop
        $script:ResultsCollection.Clear()
        if ($script:DeployPackagesCollection) {
            $script:DeployPackagesCollection.Clear()
        }

        $rawRuns = @()
        $rawRows = @()
        if ($null -ne $raw -and $raw.PSObject.Properties['Rows']) {
            if ($raw.PSObject.Properties['DeploymentRuns'] -and $raw.DeploymentRuns) {
                $rawRuns = @($raw.DeploymentRuns)
            }
            if ($raw.Rows) {
                $rawRows = @($raw.Rows)
            }
        } else {
            $rawRows = @($raw)
        }

        foreach ($run in $rawRuns) {
            if ($null -eq $run) { continue }
            $depId = if ($run.PSObject.Properties['DeploymentId'] -and -not [string]::IsNullOrWhiteSpace([string]$run.DeploymentId)) {
                [string]$run.DeploymentId
            } else {
                [guid]::NewGuid().ToString("N").Substring(0, 10)
            }
            $script:DeployPackagesCollection.Add([PSCustomObject]@{
                DeploymentId    = $depId
                PackageName     = if ($run.PackageName) { [string]$run.PackageName } else { "(Custom Package)" }
                Status          = if ($run.Status) { [string]$run.Status } else { "Success" }
                TargetCount     = if ($null -ne $run.TargetCount) { [int]$run.TargetCount } else { 0 }
                CompletedCount  = if ($null -ne $run.CompletedCount) { [int]$run.CompletedCount } else { 0 }
                SuccessCount    = if ($null -ne $run.SuccessCount) { [int]$run.SuccessCount } else { 0 }
                FailedCount     = if ($null -ne $run.FailedCount) { [int]$run.FailedCount } else { 0 }
                StoppedCount    = if ($null -ne $run.StoppedCount) { [int]$run.StoppedCount } else { 0 }
                TargetSummary   = if ($run.TargetSummary) { [string]$run.TargetSummary } else { "Completed" }
                StepsCount      = if ($null -ne $run.StepsCount) { [int]$run.StepsCount } else { 1 }
                StartTime       = if ($run.StartTime) { [string]$run.StartTime } else { "-" }
                EndTime         = if ($run.EndTime) { [string]$run.EndTime } else { "-" }
                Duration        = if ($run.Duration) { [string]$run.Duration } else { "0.0s" }
                DurationSeconds = if ($null -ne $run.DurationSeconds) { [double]$run.DurationSeconds } else { 0.0 }
                TargetComputers = if ($run.PSObject.Properties['TargetComputers'] -and $run.TargetComputers) { @($run.TargetComputers | ForEach-Object { [string]$_ }) } else { @() }
                PackageSteps    = if ($run.PSObject.Properties['PackageSteps'] -and $run.PackageSteps) { @($run.PackageSteps) } else { @() }
            })
        }

        $legacyGroups = [ordered]@{}
        foreach ($r in $rawRows) {
            if ($null -eq $r) { continue }
            $hist = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
            if ($r.StepHistory) {
                foreach ($h in $r.StepHistory) {
                    $fullDet = [string]$h.Details
                    $nonEmpty = @($fullDet -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                    $prevStr = if ($nonEmpty.Count -gt 0) { $j = $nonEmpty -join " | "; if ($j.Length -gt 180) { $j.Substring(0, 180) + "..." } else { $j } } else { "" }
                    $hist.Add([PSCustomObject]@{
                        StepIndex      = [int]$h.StepIndex
                        StepOrder      = [int]$h.StepOrder
                        StepName       = [string]$h.StepName
                        StepType       = [string]$h.StepType
                        Status         = [string]$h.Status
                        Duration       = [string]$h.Duration
                        Seconds        = [double]$h.Seconds
                        ExecutedAt     = [string]$r.Timestamp
                        Details        = $fullDet
                        DetailsPreview = $prevStr
                    })
                }
            }
            $pkgVal = if ($r.PSObject.Properties['PackageName'] -and -not [string]::IsNullOrWhiteSpace([string]$r.PackageName)) { [string]$r.PackageName } else { "(Custom Package)" }
            $startVal = if ($r.PSObject.Properties['StartTime'] -and -not [string]::IsNullOrWhiteSpace([string]$r.StartTime)) { [string]$r.StartTime } else { [string]$r.Timestamp }
            $endVal   = if ($r.PSObject.Properties['EndTime'] -and -not [string]::IsNullOrWhiteSpace([string]$r.EndTime)) {
                [string]$r.EndTime
            } elseif ([string]$r.Status -in @('Success', 'Failed')) {
                [string]$r.Timestamp
            } else {
                "-"
            }
            $depId = if ($r.PSObject.Properties['DeploymentId'] -and -not [string]::IsNullOrWhiteSpace([string]$r.DeploymentId)) {
                [string]$r.DeploymentId
            } else {
                $gKey = "$pkgVal|$($startVal.Substring(0, [Math]::Min(16, $startVal.Length)))"
                if (-not $legacyGroups.Contains($gKey)) {
                    $legacyGroups[$gKey] = [PSCustomObject]@{
                        DeploymentId = "legacy-" + [guid]::NewGuid().ToString("N").Substring(0, 8)
                        PackageName  = $pkgVal
                        StartTime    = $startVal
                        EndTime      = $endVal
                        Rows         = New-Object System.Collections.Generic.List[object]
                    }
                }
                $legacyGroups[$gKey].DeploymentId
            }

            $rowObj = [PSCustomObject]@{
                DeploymentId    = $depId
                ComputerName    = [string]$r.ComputerName
                PackageName     = $pkgVal
                Status          = [string]$r.Status
                Step            = [string]$r.Step
                Details         = [string]$r.Details
                StartTime       = $startVal
                EndTime         = $endVal
                Duration        = [string]$r.Duration
                Timestamp       = [string]$r.Timestamp
                DurationSeconds = [double]$r.DurationSeconds
                FailedStepIndex = if ($null -ne $r.FailedStepIndex) { [int]$r.FailedStepIndex } else { -1 }
                StepHistory     = $hist
            }
            $script:ResultsCollection.Add($rowObj)

            foreach ($lg in $legacyGroups.Values) {
                if ($lg.DeploymentId -eq $depId) {
                    $lg.Rows.Add($rowObj)
                    break
                }
            }
        }

        # Synthesize deployment history entries for any legacy rows that did not have DeploymentRuns saved
        foreach ($lg in $legacyGroups.Values) {
            $tot = $lg.Rows.Count
            $ok  = @($lg.Rows | Where-Object { $_.Status -eq 'Success' }).Count
            $fl  = @($lg.Rows | Where-Object { $_.Status -eq 'Failed' }).Count
            $st  = @($lg.Rows | Where-Object { $_.Status -eq 'Stopped' }).Count
            $ovStatus = if ($fl -gt 0) { "Failed" }
                        elseif ($st -gt 0) { "Stopped" }
                        elseif ($ok -gt 0 -and $ok -eq $tot) { "Success" }
                        else { "Failed" }
            $maxSec = 0.0
            $maxStepCnt = 1
            foreach ($lr in $lg.Rows) {
                if ($lr.DurationSeconds -gt $maxSec) { $maxSec = [double]$lr.DurationSeconds }
                if ($lr.StepHistory -and $lr.StepHistory.Count -gt $maxStepCnt) { $maxStepCnt = $lr.StepHistory.Count }
            }
            $script:DeployPackagesCollection.Add([PSCustomObject]@{
                DeploymentId    = $lg.DeploymentId
                PackageName     = $lg.PackageName
                Status          = $ovStatus
                TargetCount     = $tot
                CompletedCount  = $tot
                SuccessCount    = $ok
                FailedCount     = $fl
                StoppedCount    = $st
                TargetSummary   = "$tot/$tot ($ok OK, $fl Fail)"
                StepsCount      = $maxStepCnt
                StartTime       = $lg.StartTime
                EndTime         = $lg.EndTime
                Duration        = ("{0:N1}s" -f $maxSec)
                DurationSeconds = $maxSec
            })
        }

        # Reconcile all loaded DeploymentRuns against their matching computer rows in $script:ResultsCollection
        foreach ($depRun in $script:DeployPackagesCollection) {
            $matchingRows = @($script:ResultsCollection | Where-Object { $_.DeploymentId -eq $depRun.DeploymentId })
            if ($matchingRows.Count -gt 0) {
                $tot = if ($depRun.TargetCount -gt $matchingRows.Count) { [int]$depRun.TargetCount } else { [int]$matchingRows.Count }
                $ok  = @($matchingRows | Where-Object { $_.Status -eq 'Success' }).Count
                $fl  = @($matchingRows | Where-Object { $_.Status -eq 'Failed' -or $_.Status -like '*Fail*' -or $_.Status -eq 'Offline' }).Count
                $st  = @($matchingRows | Where-Object { $_.Status -in @('Stopped', 'Cancelled') }).Count
                $done = $ok + $fl + $st
                $depRun.TargetCount    = $tot
                $depRun.CompletedCount = $done
                $depRun.SuccessCount   = $ok
                $depRun.FailedCount    = $fl
                $depRun.StoppedCount   = $st
                $depRun.TargetSummary  = "$done/$tot ($ok OK, $fl Fail)"
                if ($fl -gt 0) {
                    $depRun.Status = "Failed"
                } elseif ($st -gt 0) {
                    $depRun.Status = "Stopped"
                } elseif ($ok -gt 0 -and $ok -eq $tot) {
                    $depRun.Status = "Success"
                } elseif ($depRun.Status -ne "Running") {
                    $depRun.Status = "Failed"
                }
                if ($null -eq $depRun.StepsCount -or [int]$depRun.StepsCount -le 0) {
                    $maxSt = 1
                    foreach ($mr in $matchingRows) {
                        if ($mr.StepHistory -and $mr.StepHistory.Count -gt $maxSt) { $maxSt = $mr.StepHistory.Count }
                    }
                    $depRun.StepsCount = $maxSt
                }
            } elseif ($depRun.FailedCount -gt 0) {
                $depRun.Status = "Failed"
            }
        }

        if ($dgDeployPackages) {
            $dgDeployPackages.SelectedItem = $null
            $dgDeployPackages.Items.Refresh()
        }
        Invoke-RefreshResultsFilter
    } catch {}
}

function Get-OrCreate-ComputerRow {
    param(
        [string]$ComputerName,
        [string]$PackageName = "",
        [string]$DeploymentId = ""
    )
    $resolvedPkg = if (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        $PackageName
    } elseif ($txtPkgName -and -not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) {
        $txtPkgName.Text
    } else {
        "(Untitled Package)"
    }
    $nowStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $newRow = [PSCustomObject]@{
        DeploymentId    = $DeploymentId
        ComputerName    = $ComputerName
        PackageName     = $resolvedPkg
        Status          = "Queued"
        Step            = "Pending"
        Details         = "Waiting to execute..."
        StartTime       = $nowStamp
        EndTime         = "-"
        Duration        = "0.0s"
        Timestamp       = $nowStamp
        DurationSeconds = 0.0
        FailedStepIndex = -1
        StepHistory     = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
    }
    $script:ResultsCollection.Add($newRow)
    if ($dgResults) {
        try { $dgResults.ScrollIntoView($newRow) } catch {}
    }
    return $newRow
}

function Update-ComputerRow {
    param(
        $Row,
        [string]$Status,
        [string]$Step,
        [string]$Details,
        [double]$AddSeconds = 0.0,
        [int]$FailedStepIndex = -99
    )
    if (-not $Row) { return }
    $nowStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    if ([string]::IsNullOrWhiteSpace($Row.StartTime)) {
        $Row.StartTime = $nowStamp
    }
    if ($Status) {
        $Row.Status = $Status
        if ($Status -in @('Success', 'Failed', 'Stopped', 'Cancelled')) {
            $Row.EndTime = $nowStamp
        } elseif ($Status -like 'Running*' -or $Status -eq 'Queued') {
            $Row.EndTime = "-"
        }
    }
    if ($Step)    { $Row.Step    = $Step }
    if ($Details) { $Row.Details = $Details }
    if ($AddSeconds -gt 0) {
        $Row.DurationSeconds = [double]$Row.DurationSeconds + $AddSeconds
        $Row.Duration = ("{0:N1}s" -f $Row.DurationSeconds)
    }
    if ($FailedStepIndex -ne -99) {
        $Row.FailedStepIndex = $FailedStepIndex
    }
    $Row.Timestamp = $nowStamp
    $dgResults.Items.Refresh()
}

function Format-StepDetailsPreview {
    param([string]$Text, [int]$MaxLength = 180)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $nonEmpty = @($Text -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($nonEmpty.Count -eq 0) { return "" }
    $joined = $nonEmpty -join " | "
    if ($joined.Length -gt $MaxLength) {
        return $joined.Substring(0, $MaxLength) + "..."
    }
    return $joined
}

function Set-StepHistoryEntry {
    param(
        $Row,
        [int]$StepIndex,
        [int]$StepOrder,
        [string]$StepName,
        [string]$StepType,
        [string]$Status,
        [string]$Duration,
        [double]$Seconds,
        [string]$Details
    )
    if (-not $Row) { return }
    $preview = Format-StepDetailsPreview -Text $Details
    $existing = $Row.StepHistory | Where-Object { $_.StepIndex -eq $StepIndex } | Select-Object -First 1
    if ($existing) {
        $existing.Status         = $Status
        $existing.Duration       = $Duration
        $existing.Seconds        = $Seconds
        $existing.Details        = $Details
        if ($existing.PSObject.Properties['DetailsPreview']) {
            $existing.DetailsPreview = $preview
        } else {
            $existing | Add-Member -NotePropertyName DetailsPreview -NotePropertyValue $preview -Force
        }
    } else {
        $entry = [PSCustomObject]@{
            StepIndex      = $StepIndex
            StepOrder      = $StepOrder
            StepName       = $StepName
            StepType       = $StepType
            Status         = $Status
            Duration       = $Duration
            Seconds        = $Seconds
            ExecutedAt     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Details        = $Details
            DetailsPreview = $preview
        }
        $Row.StepHistory.Add($entry)
    }
}

function Show-ComputerDeploymentDetails {
    param($ComputerRow)
    if (-not $ComputerRow) { return }

    [xml]$detailsXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Deployment Details - $($ComputerRow.ComputerName)" Height="580" Width="840"
        WindowStartupLocation="CenterOwner" Background="#1E1E2E" Foreground="#CDD6F4"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="30"/>
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="8,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition x:Name="rowDetailsSteps" Height="1.15*" MinHeight="95"/>
            <RowDefinition Height="8"/>
            <RowDefinition x:Name="rowDetailsOutput" Height="1*" MinHeight="100"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#181825" CornerRadius="6" Padding="12,10" Margin="0,0,0,10" BorderBrush="#313244" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Target Computer" FontSize="11" Foreground="#A6ADC8"/>
                    <TextBlock x:Name="lblTargetHost" Text="$($ComputerRow.ComputerName)" FontSize="18" FontWeight="Bold" Foreground="#F5E0DC"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="20,0,0,0">
                    <TextBlock Text="Status" FontSize="11" Foreground="#A6ADC8"/>
                    <TextBlock x:Name="lblTargetStatus" Text="$($ComputerRow.Status)" FontSize="16" FontWeight="Bold"/>
                </StackPanel>
                <StackPanel Grid.Column="2" Margin="20,0,0,0">
                    <TextBlock Text="Total Duration" FontSize="11" Foreground="#A6ADC8"/>
                    <TextBlock x:Name="lblTargetDuration" Text="$($ComputerRow.Duration)" FontSize="16" FontWeight="Bold" Foreground="#89B4FA"/>
                </StackPanel>
                <StackPanel Grid.Column="3" Margin="20,0,0,0">
                    <TextBlock Text="Start / End Time" FontSize="11" Foreground="#A6ADC8"/>
                    <TextBlock x:Name="lblTargetTime" Text="$($ComputerRow.StartTime) → $($ComputerRow.EndTime)" FontSize="12.5" Foreground="#CDD6F4"/>
                </StackPanel>
            </Grid>
        </Border>

        <DataGrid x:Name="dgStepHistory" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True"
                  Background="#181825" Foreground="#CDD6F4" RowBackground="#1E1E2E"
                  AlternatingRowBackground="#181825" BorderBrush="#313244" BorderThickness="1"
                  GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#313244"
                  HeadersVisibility="Column" SelectionMode="Single" Margin="0,0,0,4">
            <DataGrid.Resources>
                <Style TargetType="{x:Type DataGridColumnHeader}">
                    <Setter Property="Background" Value="#11111B"/>
                    <Setter Property="Foreground" Value="#CDD6F4"/>
                    <Setter Property="FontWeight" Value="SemiBold"/>
                    <Setter Property="Padding" Value="8,6"/>
                    <Setter Property="BorderThickness" Value="0,0,1,1"/>
                    <Setter Property="BorderBrush" Value="#313244"/>
                </Style>
                <Style TargetType="{x:Type DataGridCell}">
                    <Setter Property="Padding" Value="8,4"/>
                    <Setter Property="BorderThickness" Value="0"/>
                    <Style.Triggers>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#45475A"/>
                            <Setter Property="Foreground" Value="#F5E0DC"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </DataGrid.Resources>
            <DataGrid.Columns>
                <DataGridTextColumn Header="#" Binding="{Binding StepOrder}" Width="40"/>
                <DataGridTextColumn Header="Step Name" Binding="{Binding StepName}" Width="190"/>
                <DataGridTextColumn Header="Type" Binding="{Binding StepType}" Width="80"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="90"/>
                <DataGridTextColumn Header="Duration" Binding="{Binding Duration}" Width="80"/>
                <DataGridTextColumn Header="Executed At" Binding="{Binding ExecutedAt}" Width="140"/>
                <DataGridTextColumn Header="Details Preview" Binding="{Binding DetailsPreview}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>

        <GridSplitter Grid.Row="2" Height="6" HorizontalAlignment="Stretch" VerticalAlignment="Center"
                      Background="#313244" ShowsPreview="False" Cursor="SizeNS"
                      ToolTip="Drag up or down to expand or collapse Step Output &amp; Diagnostic Details"/>

        <Grid Grid.Row="3" Margin="0,4,0,10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="Step Output &amp; Diagnostic Details (drag splitter above to resize):" Foreground="#A6ADC8" FontWeight="SemiBold" Margin="0,0,0,4"/>
            <TextBox x:Name="txtFullStepLog" Grid.Row="1" Height="Auto" VerticalAlignment="Stretch" VerticalContentAlignment="Top"
                     Background="#11111B" Foreground="#CDD6F4" BorderBrush="#313244"
                     FontFamily="Consolas" FontSize="11" IsReadOnly="True" AcceptsReturn="True"
                     VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"
                     Padding="8,6" Margin="0"/>
        </Grid>

        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="btnCopyLog" Grid.Column="0" Content="📋 Copy Diagnostic Log" Width="Auto" MinWidth="170" Height="30" Padding="12,2"
                    Background="#45475A" Foreground="#CDD6F4" ToolTip="Copy diagnostic log to clipboard"/>
            <Button x:Name="btnCloseDetails" Grid.Column="2" Content="Close" Width="Auto" MinWidth="90" Height="30" Padding="12,2"
                    Background="#89B4FA" Foreground="#11111B" FontWeight="Bold" ToolTip="Close deployment details window"/>
        </Grid>
    </Grid>
</Window>
"@

    $rdr = New-Object System.Xml.XmlNodeReader $detailsXaml
    $dlg = [System.Windows.Markup.XamlReader]::Load($rdr)
    $dlg.Owner = $window

    $lblTargetStatus = $dlg.FindName("lblTargetStatus")
    if ($ComputerRow.Status -eq 'Success') {
        $lblTargetStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
    } elseif ($ComputerRow.Status -eq 'Failed') {
        $lblTargetStatus.Foreground = [System.Windows.Media.Brushes]::Tomato
    } elseif ($ComputerRow.Status -like 'Running*') {
        $lblTargetStatus.Foreground = [System.Windows.Media.Brushes]::Khaki
    } else {
        $lblTargetStatus.Foreground = [System.Windows.Media.Brushes]::LightGray
    }

    $dgStepHistory   = $dlg.FindName("dgStepHistory")
    $txtFullStepLog  = $dlg.FindName("txtFullStepLog")
    $btnCopyLog      = $dlg.FindName("btnCopyLog")
    $btnCloseDetails = $dlg.FindName("btnCloseDetails")

    $dgStepHistory.ItemsSource = $ComputerRow.StepHistory

    $updateLogText = {
        $sel = $dgStepHistory.SelectedItem
        if ($sel) {
            $txtFullStepLog.Text = "=== Step $($sel.StepOrder): $($sel.StepName) ($($sel.StepType)) ===`r`nStatus:   $($sel.Status)`r`nDuration: $($sel.Duration)`r`nTime:     $($sel.ExecutedAt)`r`n`r`nDetails / Diagnostic Output:`r`n$($sel.Details)"
        } else {
            $txtFullStepLog.Text = "Target: $($ComputerRow.ComputerName)`r`nStatus: $($ComputerRow.Status)`r`nTotal:  $($ComputerRow.Duration)`r`n`r`nLatest Output:`r`n$($ComputerRow.Details)"
        }
    }

    $dgStepHistory.Add_SelectionChanged($updateLogText)
    if ($ComputerRow.StepHistory -and $ComputerRow.StepHistory.Count -gt 0) {
        $dgStepHistory.SelectedIndex = 0
    }
    & $updateLogText

    $btnCopyLog.Add_Click({
        if (-not [string]::IsNullOrWhiteSpace($txtFullStepLog.Text)) {
            [System.Windows.Clipboard]::SetText($txtFullStepLog.Text)
            [System.Windows.MessageBox]::Show("Diagnostic log copied to clipboard.", "Copied", "OK", "Information")
        }
    })

    $btnCloseDetails.Add_Click({ $dlg.Close() })
    $rowDetailsSteps  = $dlg.FindName("rowDetailsSteps")
    $rowDetailsOutput = $dlg.FindName("rowDetailsOutput")
    Register-ChildWindowLayoutPersistence -Dialog $dlg -WindowKey "DeploymentDetails" -TopRow $rowDetailsSteps -BottomRow $rowDetailsOutput
    [void]$dlg.ShowDialog()
}

$dgResults.Add_MouseDoubleClick({
    $sel = $dgResults.SelectedItem
    if ($sel) { Show-ComputerDeploymentDetails -ComputerRow $sel }
})

# Windows 11 Context Menu on Results DataGrid
$ctxResults = New-Win11ContextMenu

$resQuickBarHost = New-Object System.Windows.Controls.MenuItem
$resQuickBarHost.StaysOpenOnClick = $true
$resQuickBarHost.Padding = New-Object System.Windows.Thickness(2, 2, 2, 2)

$resQuickPanel = New-Object System.Windows.Controls.StackPanel
$resQuickPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$resQuickPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

$btnQResDetails = New-Win11QuickActionButton -Glyph "🔍" -Label "Details" -GlyphColor "#89B4FA" -ToolTipText "Open detailed multi-step output logs"
$btnQResDetails.Tag = $ctxResults
$btnQResDetails.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgResults.SelectedItem
    if ($sel) { Show-ComputerDeploymentDetails -ComputerRow $sel }
})
[void]$resQuickPanel.Children.Add($btnQResDetails)

$btnQResRedeploy = New-Win11QuickActionButton -Glyph "🔁" -Label "Re-Deploy" -GlyphColor "#A6E3A1" -ToolTipText "Re-deploy package to selected computer"
$btnQResRedeploy.Tag = $ctxResults
$btnQResRedeploy.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgResults.SelectedItem
    if ($sel) {
        $rPkgName = if ($sel.PSObject.Properties['PackageName'] -and -not [string]::IsNullOrWhiteSpace([string]$sel.PackageName)) { [string]$sel.PackageName } else { "" }
        $rSteps   = @(Resolve-DeploymentPackageSteps -PackageName $rPkgName -DeployRun $dgDeployPackages.SelectedItem)
        Invoke-DeploymentForTargets -TargetComputers @($sel.ComputerName) -StartStepIndex 0 -PackageName $rPkgName -PackageSteps $rSteps
    }
})
[void]$resQuickPanel.Children.Add($btnQResRedeploy)

$btnQResCopy = New-Win11QuickActionButton -Glyph "📋" -Label "Copy Log" -GlyphColor "#CBA6F7" -ToolTipText "Copy row summary &amp; output to clipboard"
$btnQResCopy.Tag = $ctxResults
$btnQResCopy.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgResults.SelectedItem
    if ($sel) {
        $summaryText = "Computer: $($sel.ComputerName) | Package: $($sel.PackageName) | Step: $($sel.Step) | Status: $($sel.Status) | Start: $($sel.StartTime) | End: $($sel.EndTime) | Duration: $($sel.Duration)`r`nDetails: $($sel.Details)"
        [System.Windows.Clipboard]::SetText($summaryText)
        $lblStatus.Text = "Copied deployment result for '$($sel.ComputerName)' to clipboard."
    }
})
[void]$resQuickPanel.Children.Add($btnQResCopy)

$btnQResDelete = New-Win11QuickActionButton -Glyph "🗑" -Label "Delete" -GlyphColor "#F38BA8" -ToolTipText "Delete selected status log row"
$btnQResDelete.Tag = $ctxResults
$btnQResDelete.Add_Click({
    param($s, $e)
    $s.Tag.IsOpen = $false
    $sel = $dgResults.SelectedItem
    if ($sel) {
        [void]$script:ResultsCollection.Remove($sel)
        Save-PersistentStatusState
    }
})
[void]$resQuickPanel.Children.Add($btnQResDelete)

$resQuickBarHost.Header = $resQuickPanel
[void]$ctxResults.Items.Add($resQuickBarHost)
[void]$ctxResults.Items.Add((New-Object System.Windows.Controls.Separator))

$menuViewDetails = New-Object System.Windows.Controls.MenuItem
$menuViewDetails.Header = "View Detailed Multi-Step Logs..."
$menuViewDetails.InputGestureText = "Enter"
$menuViewDetails.Icon = New-Win11MenuIcon -Glyph "🔍" -ColorHex "#89B4FA"
$menuViewDetails.Add_Click({
    $sel = $dgResults.SelectedItem
    if ($sel) { Show-ComputerDeploymentDetails -ComputerRow $sel }
})
[void]$ctxResults.Items.Add($menuViewDetails)

$menuRedeploy = New-Object System.Windows.Controls.MenuItem
$menuRedeploy.Header = "Re-Deploy to This Computer"
$menuRedeploy.InputGestureText = "Ctrl+R"
$menuRedeploy.Icon = New-Win11MenuIcon -Glyph "🔁" -ColorHex "#A6E3A1"
$menuRedeploy.Add_Click({
    $sel = $dgResults.SelectedItem
    if ($sel) {
        $rPkgName = if ($sel.PSObject.Properties['PackageName'] -and -not [string]::IsNullOrWhiteSpace([string]$sel.PackageName)) { [string]$sel.PackageName } else { "" }
        $rSteps   = @(Resolve-DeploymentPackageSteps -PackageName $rPkgName -DeployRun $dgDeployPackages.SelectedItem)
        Invoke-DeploymentForTargets -TargetComputers @($sel.ComputerName) -StartStepIndex 0 -PackageName $rPkgName -PackageSteps $rSteps
    }
})
[void]$ctxResults.Items.Add($menuRedeploy)

$menuCopyResLog = New-Object System.Windows.Controls.MenuItem
$menuCopyResLog.Header = "Copy Diagnostic Output to Clipboard"
$menuCopyResLog.InputGestureText = "Ctrl+C"
$menuCopyResLog.Icon = New-Win11MenuIcon -Glyph "📋" -ColorHex "#CBA6F7"
$menuCopyResLog.Add_Click({
    $sel = $dgResults.SelectedItem
    if ($sel) {
        $summaryText = "Computer: $($sel.ComputerName) | Package: $($sel.PackageName) | Step: $($sel.Step) | Status: $($sel.Status) | Start: $($sel.StartTime) | End: $($sel.EndTime) | Duration: $($sel.Duration)`r`nDetails: $($sel.Details)"
        [System.Windows.Clipboard]::SetText($summaryText)
        $lblStatus.Text = "Copied deployment result for '$($sel.ComputerName)' to clipboard."
    }
})
[void]$ctxResults.Items.Add($menuCopyResLog)

[void]$ctxResults.Items.Add((New-Object System.Windows.Controls.Separator))

$menuClearLogFiltersCtx = New-Object System.Windows.Controls.MenuItem
$menuClearLogFiltersCtx.Header = "Clear All Status Log Filters"
$menuClearLogFiltersCtx.InputGestureText = "Reset"
$menuClearLogFiltersCtx.Icon = New-Win11MenuIcon -Glyph "🧹" -ColorHex "#F9E2AF"
$menuClearLogFiltersCtx.Add_Click({
    Clear-AllResultFilters
})
[void]$ctxResults.Items.Add($menuClearLogFiltersCtx)

$menuDelResRow = New-Object System.Windows.Controls.MenuItem
$menuDelResRow.Header = "Delete Status Row"
$menuDelResRow.InputGestureText = "Del"
$menuDelResRow.Icon = New-Win11MenuIcon -Glyph "✕" -ColorHex "#F38BA8"
$menuDelResRow.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F38BA8")
$menuDelResRow.Add_Click({
    $sel = $dgResults.SelectedItem
    if ($sel) {
        [void]$script:ResultsCollection.Remove($sel)
        Save-PersistentStatusState
    }
})
[void]$ctxResults.Items.Add($menuDelResRow)
$dgResults.ContextMenu = $ctxResults

$btnDeleteRow.Add_Click({
    $sel = $dgResults.SelectedItem
    if ($sel) {
        [void]$script:ResultsCollection.Remove($sel)
        Save-PersistentStatusState
    } else {
        [System.Windows.MessageBox]::Show("Select a row in the Results table to delete.", "Delete Row", "OK", "Information")
    }
})

$btnClearStatus.Add_Click({
    if ($script:ResultsCollection.Count -eq 0 -and $script:DeployPackagesCollection.Count -eq 0) { return }
    $ans = [System.Windows.MessageBox]::Show("Clear all completed deployment history and status results?", "Clear Status", "YesNo", "Question")
    if ($ans -eq 'Yes') {
        $finishedRuns = @($script:DeployPackagesCollection | Where-Object { $_.Status -ne "Running" })
        foreach ($fr in $finishedRuns) {
            [void]$script:DeployPackagesCollection.Remove($fr)
        }
        $runningIds = @{}
        foreach ($rr in $script:DeployPackagesCollection) {
            if ($rr.DeploymentId) { $runningIds[[string]$rr.DeploymentId] = $true }
        }
        $toRem = @($script:ResultsCollection | Where-Object {
            $id = if ($_.PSObject.Properties['DeploymentId']) { [string]$_.DeploymentId } else { "" }
            -not $runningIds.ContainsKey($id)
        })
        foreach ($r in $toRem) {
            [void]$script:ResultsCollection.Remove($r)
        }
        Save-PersistentStatusState
        if ($dgDeployPackages) { $dgDeployPackages.Items.Refresh() }
        Invoke-RefreshResultsFilter
        $lblStatus.Text = "Cleared all completed deployment history and status records."
    }
})

$btnSaveLogs.Add_Click({
    if ($script:ResultsCollection.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No status records available to save.", "Save Logs", "OK", "Information")
        return
    }

    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "CSV Files (*.csv)|*.csv|Log Text Files (*.txt)|*.txt"
    $sfd.FileName = "DeploymentLogs_$((Get-Date).ToString('yyyyMMdd_HHmmss')).csv"
    if ($script:LogsDir -and (Test-Path $script:LogsDir)) {
        $sfd.InitialDirectory = $script:LogsDir
    }
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $exportRows = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($r in $script:ResultsCollection) {
                if ($r.StepHistory -and $r.StepHistory.Count -gt 0) {
                    foreach ($s in $r.StepHistory) {
                        $exportRows.Add([PSCustomObject]@{
                            StartTime       = $r.StartTime
                            EndTime         = $r.EndTime
                            Timestamp       = $r.Timestamp
                            ComputerName    = $r.ComputerName
                            PackageName     = if ($r.PSObject.Properties['PackageName']) { $r.PackageName } else { "" }
                            OverallStatus   = $r.Status
                            OverallDuration = $r.Duration
                            StepNumber      = $s.StepOrder
                            StepName        = $s.StepName
                            StepType        = $s.StepType
                            StepStatus      = $s.Status
                            StepDuration    = $s.Duration
                            ExecutedAt      = $s.ExecutedAt
                            Details         = $s.Details
                        })
                    }
                } else {
                    $exportRows.Add([PSCustomObject]@{
                        StartTime       = $r.StartTime
                        EndTime         = $r.EndTime
                        Timestamp       = $r.Timestamp
                        ComputerName    = $r.ComputerName
                        PackageName     = if ($r.PSObject.Properties['PackageName']) { $r.PackageName } else { "" }
                        OverallStatus   = $r.Status
                        OverallDuration = $r.Duration
                        StepNumber      = "-"
                        StepName        = $r.Step
                        StepType        = "-"
                        StepStatus      = $r.Status
                        StepDuration    = $r.Duration
                        ExecutedAt      = $r.Timestamp
                        Details         = $r.Details
                    })
                }
            }
            $exportRows | Export-Csv -Path $sfd.FileName -NoTypeInformation -Encoding UTF8
            $lblStatus.Text = "Saved status logs to $($sfd.FileName)."
            [System.Windows.MessageBox]::Show("Status logs saved successfully to:`n$($sfd.FileName)", "Logs Saved", "OK", "Information")
        } catch {
            [System.Windows.MessageBox]::Show("Failed to save status logs: $($_.Exception.Message)", "Save Error", "OK", "Error")
        }
    }
})

# ==========================================
# 9. REFACTORED DEPLOYMENT ENGINE
# ==========================================
function Invoke-DeploymentForTargets {
    param(
        [string[]]$TargetComputers,
        [int]$StartStepIndex = 0,
        [string]$PackageName = "",
        [array]$PackageSteps = $null
    )

    if (-not $TargetComputers -or $TargetComputers.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No target systems specified for deployment.", "Validation Error", "OK", "Warning")
        return
    }

    $steps = @(if ($null -ne $PackageSteps -and @($PackageSteps).Count -gt 0) {
        $PackageSteps
    } else {
        $script:StepsCollection
    })

    if ($steps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("The selected package has no steps to deploy.", "Validation Error", "OK", "Warning")
        return
    }

    $hasRemoteTargets = @($TargetComputers | Where-Object { -not (Test-IsLocalComputer -ComputerName $_) }).Count -gt 0
    $useCurrentCred = [bool]$script:AppSettings.UseCurrentCred
    $hasSavedCred = (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Username)) -and ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0)
    if ($hasRemoteTargets -and -not $useCurrentCred -and -not $hasSavedCred) {
        $ans = [System.Windows.MessageBox]::Show("Admin credentials are not configured.`n`nOpen Settings dialog now to configure credentials or select current logon?", "Credentials Required", "YesNo", "Warning")
        if ($ans -eq 'Yes') {
            Show-SettingsDialog
            $useCurrentCred = [bool]$script:AppSettings.UseCurrentCred
            $hasSavedCred = (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Username)) -and ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0)
        }
        if (-not $useCurrentCred -and -not $hasSavedCred) {
            return
        }
    }

    if ($StartStepIndex -lt 0 -or $StartStepIndex -ge $steps.Count) {
        $StartStepIndex = 0
    }

    $sampleCred = if (-not $useCurrentCred) {
        Get-TargetCredential -TargetComputer $TargetComputers[0] -DomainInput $script:AppSettings.Domain -UserInput $script:AppSettings.Username -SecurePassword $script:AppSettings.SecurePassword
    } else {
        @{ CredKind = 'Current' }
    }

    $missingTH = @(Get-MissingTrustedHosts -TargetList $TargetComputers -Kind $sampleCred.CredKind)
    if ($missingTH.Count -gt 0) {
        $thMsg = "These targets require addition to WinRM TrustedHosts for credentials to be accepted:`n`n$($missingTH -join "`n")`n`nAdd them now via elevated prompt?"
        $choice = [System.Windows.MessageBox]::Show($thMsg, "TrustedHosts Preflight", "YesNoCancel", "Warning")
        if ($choice -eq 'Cancel') { return }
        if ($choice -eq 'Yes') {
            Add-TrustedHostsElevated -HostsToAdd $missingTH | Out-Null
        }
    }

    $continueOnError = [bool]$chkContinueOnError.IsChecked
    $maxConcurrency = if ($null -ne $script:AppSettings.MaxConcurrentTargets -and [int]$script:AppSettings.MaxConcurrentTargets -ge 1) {
        [Math]::Min(8, [Math]::Max(1, [int]$script:AppSettings.MaxConcurrentTargets))
    } else { 8 }

    $pkgName = if (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        $PackageName.Trim()
    } elseif ($txtPkgName -and -not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) {
        $txtPkgName.Text.Trim()
    } else {
        "(Untitled Package)"
    }
    $stepsToRun = @($steps | Select-Object -Skip $StartStepIndex)
    Write-DiagnosticLog "Deployment started: Package='$pkgName', Targets=$($TargetComputers -join ', '), Steps=$($stepsToRun.Count), MaxConcurrency=$maxConcurrency"

    $remoteStagingBase = if (-not [string]::IsNullOrWhiteSpace($script:AppSettings.RemoteStagingDir)) { $script:AppSettings.RemoteStagingDir } else { "C:\Temp\PSDeploy" }

    # Snapshot steps as thread-safe plain hashtables for RunspacePool workers
    $stepOrderIdx = 0
    $stepsData = @(foreach ($s in $steps) {
        $stepOrderIdx++
        $ord = if ($null -ne $s.Order -and [int]$s.Order -gt 0) { [int]$s.Order } else { $stepOrderIdx }
        @{
            Order         = $ord
            Name          = [string]$s.Name
            Type          = [string]$s.Type
            Script        = [string]$s.Script
            Parameters    = [string]$s.Parameters
            PayloadPath   = [string]$s.PayloadPath
            IncludeFolder = [bool]$s.IncludeFolder
            SilentInstall = [bool]$s.SilentInstall
            PauseSeconds  = if ($null -ne $s.PauseSeconds) { [int]$s.PauseSeconds } else { 0 }
        }
    })

    # Create Deployment Run record in $script:DeployPackagesCollection (Running Deployments & History)
    $deploymentId  = [guid]::NewGuid().ToString("N").Substring(0, 10)
    $runStartStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $stepTotalCnt  = [Math]::Max(1, [int]@($steps).Count)
    $deployRun = [PSCustomObject]@{
        DeploymentId    = $deploymentId
        PackageName     = $pkgName
        Status          = "Running"
        TargetCount     = [int]@($TargetComputers).Count
        CompletedCount  = 0
        SuccessCount    = 0
        FailedCount     = 0
        StoppedCount    = 0
        TargetSummary   = "0/$(@($TargetComputers).Count) (Running)"
        StepsCount      = $stepTotalCnt
        StartTime       = $runStartStamp
        EndTime         = "-"
        Duration        = "0.0s"
        DurationSeconds = 0.0
        TargetComputers = @($TargetComputers | ForEach-Object { [string]$_ })
        PackageSteps    = @($stepsData)
    }
    $script:DeployPackagesCollection.Insert(0, $deployRun)

    # Pre-create UI rows and resolve per-target credentials on main UI thread
    $targetContextMap = @{}
    foreach ($computer in $TargetComputers) {
        $row = Get-OrCreate-ComputerRow -ComputerName $computer -PackageName $pkgName -DeploymentId $deploymentId
        $credInfo = if (-not $useCurrentCred) {
            Get-TargetCredential -TargetComputer $computer -DomainInput $script:AppSettings.Domain -UserInput $script:AppSettings.Username -SecurePassword $script:AppSettings.SecurePassword
        } else {
            @{ Credential = $null; CredKind = 'Current'; UserString = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name }
        }
        $targetContextMap[$computer] = @{
            Row      = $row
            CredInfo = $credInfo
            Done     = $false
        }
    }

    $eventQueue  = New-Object 'System.Collections.Concurrent.ConcurrentQueue[psobject]'
    $sharedState = [hashtable]::Synchronized(@{ CancelRequested = $false })
    $script:ActiveDeploySharedState = $sharedState

    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    foreach ($fnName in @('Test-IsLocalComputer', 'Test-TargetReachable', 'Get-WinRMHint')) {
        $fnCmd = Get-Command $fnName -CommandType Function -ErrorAction SilentlyContinue
        if ($fnCmd) {
            $iss.Commands.Add((New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry($fnName, $fnCmd.Definition)))
        }
    }

    $pool = [runspacefactory]::CreateRunspacePool(1, $maxConcurrency, $iss, $Host)
    $pool.Open()
    $workerHandles = New-Object System.Collections.Generic.List[object]

    $workerScript = {
        param(
            [string]$Computer,
            [array]$Steps,
            [int]$StartStepIndex,
            [bool]$ContinueOnError,
            [string]$RemoteStaging,
            [hashtable]$CredInfo,
            [string]$StepRunnerCode,
            [hashtable]$SharedState,
            $EventQueue
        )

        function Send-Log([string]$Msg, [string]$Level = "INFO") {
            $EventQueue.Enqueue([PSCustomObject]@{
                EventType = 'Log'
                Computer  = $Computer
                Message   = $Msg
                Level     = $Level
            })
        }

        function Send-RowUpdate([string]$Step, [string]$Status, [string]$Details, [double]$AddSeconds = 0.0, [int]$FailedStepIndex = -1, [string]$LiveDuration = "") {
            $EventQueue.Enqueue([PSCustomObject]@{
                EventType       = 'RowUpdate'
                Computer        = $Computer
                Step            = $Step
                Status          = $Status
                Details         = $Details
                AddSeconds      = $AddSeconds
                FailedStepIndex = $FailedStepIndex
                LiveDuration    = $LiveDuration
            })
        }

        function Send-StepHistory([int]$StepIndex, [int]$StepOrder, [string]$StepName, [string]$StepType, [string]$Status, [string]$Duration, [double]$Seconds, [string]$Details) {
            $EventQueue.Enqueue([PSCustomObject]@{
                EventType = 'StepHistory'
                Computer  = $Computer
                StepIndex = $StepIndex
                StepOrder = $StepOrder
                StepName  = $StepName
                StepType  = $StepType
                Status    = $Status
                Duration  = $Duration
                Seconds   = $Seconds
                Details   = $Details
            })
        }

        function Send-TargetDone([string]$Outcome) {
            $EventQueue.Enqueue([PSCustomObject]@{
                EventType = 'TargetDone'
                Computer  = $Computer
                Outcome   = $Outcome
            })
        }

        $runnerSb = [scriptblock]::Create($StepRunnerCode)

        if ($SharedState.CancelRequested) {
            $stopMsg = "Deployment stopped by user before starting target '$Computer'."
            Send-Log $stopMsg "WARN"
            Send-RowUpdate -Step "$($Steps[$StartStepIndex].Order). $($Steps[$StartStepIndex].Name)" -Status "Stopped" -Details $stopMsg
            for ($idx = $StartStepIndex; $idx -lt $Steps.Count; $idx++) {
                $st = $Steps[$idx]
                $stStatus = if ($idx -eq $StartStepIndex) { "Stopped" } else { "Skipped" }
                $stDetails = if ($idx -eq $StartStepIndex) { $stopMsg } else { "Skipped — deployment stopped by user." }
                Send-StepHistory -StepIndex $idx -StepOrder $st.Order -StepName $st.Name -StepType $st.Type -Status $stStatus -Duration "0.0s" -Seconds 0.0 -Details $stDetails
            }
            Send-TargetDone "Stopped"
            return
        }

        $isLocalHost = Test-IsLocalComputer -ComputerName $Computer
        if ($isLocalHost) {
            $isReachable = $true
            Send-Log "Target '$Computer': Local computer detected — executing directly on local machine (bypassing WinRM)."
        } else {
            Send-RowUpdate -Step "Preflight Check" -Status "Running..." -Details "Checking network/WinRM reachability on $Computer..."
            Send-Log "Target '$Computer': Reachability check..."
            $isReachable = Test-TargetReachable -ComputerName $Computer -TimeoutMs 2500
        }

        if ($SharedState.CancelRequested) {
            $stopMsg = "Deployment stopped by user during reachability check."
            Send-RowUpdate -Step "$($Steps[$StartStepIndex].Order). $($Steps[$StartStepIndex].Name)" -Status "Stopped" -Details $stopMsg
            for ($idx = $StartStepIndex; $idx -lt $Steps.Count; $idx++) {
                $st = $Steps[$idx]
                $stStatus = if ($idx -eq $StartStepIndex) { "Stopped" } else { "Skipped" }
                $stDetails = if ($idx -eq $StartStepIndex) { $stopMsg } else { "Skipped — deployment stopped by user." }
                Send-StepHistory -StepIndex $idx -StepOrder $st.Order -StepName $st.Name -StepType $st.Type -Status $stStatus -Duration "0.0s" -Seconds 0.0 -Details $stDetails
            }
            Send-TargetDone "Stopped"
            return
        }

        if (-not $isReachable) {
            Send-Log "Target '$Computer': Offline (not reachable on WinRM ports or ICMP ping)." "WARN"
            $failMsg = "OFFLINE: Target not reachable on WinRM ports (5985/5986) or ICMP ping."
            Send-RowUpdate -Step "$($Steps[0].Order). $($Steps[0].Name)" -Status "Failed" -Details $failMsg -FailedStepIndex 0
            for ($idx = 0; $idx -lt $Steps.Count; $idx++) {
                $st = $Steps[$idx]
                $stStatus = if ($idx -eq 0) { "Failed" } else { "Skipped" }
                $stDetails = if ($idx -eq 0) { $failMsg } else { "Skipped — host offline." }
                Send-StepHistory -StepIndex $idx -StepOrder $st.Order -StepName $st.Name -StepType $st.Type -Status $stStatus -Duration "0.0s" -Seconds 0.0 -Details $stDetails
            }
            Send-TargetDone "Failed"
            return
        }

        $session = $null
        if (-not $isLocalHost) {
            $authStr = if ($CredInfo.Credential) { $CredInfo.Credential.UserName } else { 'DefaultLogon' }
            Send-Log "Target '$Computer': Opening WinRM PSSession (Auth=$authStr)..."
            try {
                $sOpt = New-PSSessionOption -OpenTimeout 15000 -OperationTimeout 180000 -CancelTimeout 10000
                $sessParams = @{
                    ComputerName  = $Computer
                    SessionOption = $sOpt
                    ErrorAction   = 'Stop'
                }
                if ($CredInfo.Credential) {
                    $sessParams['Credential'] = $CredInfo.Credential
                }
                $session = New-PSSession @sessParams
                Send-Log "Target '$Computer': WinRM PSSession opened successfully."
            }
            catch {
                if ($SharedState.CancelRequested) {
                    $stopMsg = "Deployment stopped by user while opening WinRM session."
                    Send-RowUpdate -Step "$($Steps[$StartStepIndex].Order). $($Steps[$StartStepIndex].Name)" -Status "Stopped" -Details $stopMsg
                    for ($idx = $StartStepIndex; $idx -lt $Steps.Count; $idx++) {
                        $st = $Steps[$idx]
                        $stStatus = if ($idx -eq $StartStepIndex) { "Stopped" } else { "Skipped" }
                        $stDetails = if ($idx -eq $StartStepIndex) { $stopMsg } else { "Skipped — deployment stopped by user." }
                        Send-StepHistory -StepIndex $idx -StepOrder $st.Order -StepName $st.Name -StepType $st.Type -Status $stStatus -Duration "0.0s" -Seconds 0.0 -Details $stDetails
                    }
                    Send-TargetDone "Stopped"
                    return
                }
                $rawError = $_.Exception.Message
                Send-Log "Target '$Computer': WinRM PSSession failed: $rawError" "ERROR"
                $hint = Get-WinRMHint -Message $rawError -CredKind $CredInfo.CredKind
                $failMsg = "WINRM SESSION FAILED (Auth: $($CredInfo.UserString)): $hint$rawError"
                Send-RowUpdate -Step "$($Steps[0].Order). $($Steps[0].Name)" -Status "Failed" -Details $failMsg -FailedStepIndex 0
                for ($idx = 0; $idx -lt $Steps.Count; $idx++) {
                    $st = $Steps[$idx]
                    $stStatus = if ($idx -eq 0) { "Failed" } else { "Skipped" }
                    $stDetails = if ($idx -eq 0) { $failMsg } else { "Skipped — session initialization failed." }
                    Send-StepHistory -StepIndex $idx -StepOrder $st.Order -StepName $st.Name -StepType $st.Type -Status $stStatus -Duration "0.0s" -Seconds 0.0 -Details $stDetails
                }
                Send-TargetDone "Failed"
                return
            }
        }

        $compFailed  = $false
        $compStopped = $false
        try {
            for ($i = $StartStepIndex; $i -lt $Steps.Count; $i++) {
                if ($SharedState.CancelRequested) {
                    $compStopped = $true
                    $stopMsg = "Deployment stopped by user before step $($Steps[$i].Order) ($($Steps[$i].Name))."
                    Send-RowUpdate -Step "$($Steps[$i].Order). $($Steps[$i].Name)" -Status "Stopped" -Details $stopMsg
                    for ($skipIdx = $i; $skipIdx -lt $Steps.Count; $skipIdx++) {
                        $skipStep = $Steps[$skipIdx]
                        $stStatus = if ($skipIdx -eq $i) { "Stopped" } else { "Skipped" }
                        $stDet = if ($skipIdx -eq $i) { $stopMsg } else { "Skipped — deployment stopped by user." }
                        Send-StepHistory -StepIndex $skipIdx -StepOrder $skipStep.Order -StepName $skipStep.Name -StepType $skipStep.Type -Status $stStatus -Duration "0.0s" -Seconds 0.0 -Details $stDet
                    }
                    break
                }

                $step = $Steps[$i]
                $stepDesc = "$($step.Order). $($step.Name)"
                Send-RowUpdate -Step $stepDesc -Status "Running..." -Details "Executing step $($step.Order)..."
                Send-Log "Target '$Computer': Starting Step $($step.Order) ('$($step.Name)', Type=$($step.Type))..."

                $sw = [System.Diagnostics.Stopwatch]::StartNew()

                if ($step.Type -eq 'Pause') {
                    $waited = 0.0
                    while ($waited -lt $step.PauseSeconds) {
                        if ($SharedState.CancelRequested) { break }
                        Start-Sleep -Milliseconds 250
                        $waited += 0.25
                    }
                    $sw.Stop()
                    $stepDurStr = ("{0:N1}s" -f $sw.Elapsed.TotalSeconds)
                    if ($SharedState.CancelRequested) {
                        $compStopped = $true
                        $stopDet = "Pause step stopped by user after $stepDurStr."
                        Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Stopped" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $stopDet
                        for ($skipIdx = $i + 1; $skipIdx -lt $Steps.Count; $skipIdx++) {
                            $skipStep = $Steps[$skipIdx]
                            Send-StepHistory -StepIndex $skipIdx -StepOrder $skipStep.Order -StepName $skipStep.Name -StepType $skipStep.Type -Status "Skipped" -Duration "0.0s" -Seconds 0.0 -Details "Skipped — deployment stopped by user."
                        }
                        Send-RowUpdate -Step $stepDesc -Status "Stopped" -Details $stopDet -AddSeconds $sw.Elapsed.TotalSeconds
                        Send-Log "Target '$Computer': Step $($step.Order) stopped by user." "WARN"
                        break
                    }
                    $stepDet = "Paused for $($step.PauseSeconds)s."
                    Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Success" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $stepDet
                    Send-RowUpdate -Step $stepDesc -Status "Running..." -Details $stepDet -AddSeconds $sw.Elapsed.TotalSeconds
                    Send-Log "Target '$Computer': Step $($step.Order) complete. Status=Success, Duration=$stepDurStr, Details=$stepDet"
                    continue
                }

                $payloadFileOnly = ""
                if ($step.Type -eq 'Installer' -and -not [string]::IsNullOrWhiteSpace($step.PayloadPath)) {
                    if (Test-Path $step.PayloadPath) {
                        $payloadFileOnly = [System.IO.Path]::GetFileName($step.PayloadPath)
                        Send-RowUpdate -Step $stepDesc -Status "Running..." -Details "Staging payload ($payloadFileOnly) to target..."
                        Send-Log "Target '$Computer': Staging payload '$payloadFileOnly' (IncludeFolder=$($step.IncludeFolder))..."

                        $remoteStepDir = "$RemoteStaging\Step_$($step.Order)"
                        if ($isLocalHost) {
                            if (-not (Test-Path -LiteralPath $remoteStepDir)) {
                                [void][System.IO.Directory]::CreateDirectory($remoteStepDir)
                            }
                            if ($step.IncludeFolder) {
                                $parentDir = [System.IO.Path]::GetDirectoryName($step.PayloadPath)
                                Copy-Item -LiteralPath $parentDir -Destination $RemoteStaging -Recurse -Force
                            } else {
                                Copy-Item -LiteralPath $step.PayloadPath -Destination $remoteStepDir -Force
                            }
                        } else {
                            Invoke-Command -Session $session -ScriptBlock {
                                param($d)
                                if (-not (Test-Path $d)) { [void][System.IO.Directory]::CreateDirectory($d) }
                            } -ArgumentList $remoteStepDir

                            if ($step.IncludeFolder) {
                                $parentDir = [System.IO.Path]::GetDirectoryName($step.PayloadPath)
                                Copy-Item -LiteralPath $parentDir -Destination $RemoteStaging -ToSession $session -Recurse -Force
                            } else {
                                Copy-Item -LiteralPath $step.PayloadPath -Destination $remoteStepDir -ToSession $session -Force
                            }
                        }
                        Send-Log "Target '$Computer': Payload staging complete."
                    } else {
                        $sw.Stop()
                        $errText = "Installer payload file not found locally: $($step.PayloadPath)"
                        Send-Log "Target '$Computer': Step $($step.Order) failed - payload not found: $($step.PayloadPath)" "ERROR"
                        Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Failed" -Duration "0.0s" -Seconds 0.0 -Details $errText
                        Send-RowUpdate -Step $stepDesc -Status "Failed" -Details $errText -FailedStepIndex $i
                        $compFailed = $true
                        if (-not $ContinueOnError) { break }
                        continue
                    }
                }

                $job = $null
                $localPs = $null
                try {
                    $invokeArgs = @($step.Script, $step.Parameters, $RemoteStaging, $step.Order, $step.Name, $step.Type, $payloadFileOnly, ([bool]$step.SilentInstall))
                    $lastLiveLine = ""
                    $streamItems = [System.Collections.Generic.List[Object]]::new()
                    $lastHeartbeat = 0
                    $lastSecTick = -1
                    $stepWasStopped = $false

                    if ($isLocalHost) {
                        $localPs = [powershell]::Create()
                        [void]$localPs.AddScript($runnerSb)
                        foreach ($argVal in $invokeArgs) { [void]$localPs.AddArgument($argVal) }
                        $localOut = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
                        $localAsync = $localPs.BeginInvoke($null, $localOut)
                        $localReadIdx = 0

                        while (-not $localAsync.IsCompleted) {
                            for ($pollTick = 0; $pollTick -lt 5; $pollTick++) {
                                Start-Sleep -Milliseconds 50
                                if ($SharedState.CancelRequested) { break }
                            }
                            if ($SharedState.CancelRequested) {
                                $stepWasStopped = $true
                                try { $localPs.Stop() } catch {}
                                break
                            }
                            while ($localReadIdx -lt $localOut.Count) {
                                $item = $localOut[$localReadIdx]
                                $localReadIdx++
                                if ($null -ne $item) {
                                    $streamItems.Add($item)
                                    if ($item.PSObject.Properties['IsLiveProgress'] -and $item.IsLiveProgress -eq $true) {
                                        $lastLiveLine = $item.Line
                                    }
                                }
                            }
                            $currentSec = [int]$sw.Elapsed.TotalSeconds
                            if ($currentSec -ne $lastSecTick) {
                                $lastSecTick = $currentSec
                                $currentDur = ("{0:N1}s" -f $sw.Elapsed.TotalSeconds)
                                $currentDetails = if ($lastLiveLine) { $lastLiveLine } else { "Executing step $($step.Order) locally on $Computer... ($currentDur)" }
                                Send-RowUpdate -Step $stepDesc -Status "Running..." -Details $currentDetails -LiveDuration $currentDur
                            }
                            if ($currentSec - $lastHeartbeat -ge 10) {
                                $lastHeartbeat = $currentSec
                                Send-Log "Target '$Computer': Step $($step.Order) heartbeat - running locally for $($currentSec)s..."
                            }
                        }

                        if (-not $stepWasStopped -and -not $SharedState.CancelRequested) {
                            try { $null = $localPs.EndInvoke($localAsync) } catch {}
                            while ($localReadIdx -lt $localOut.Count) {
                                $item = $localOut[$localReadIdx]
                                $localReadIdx++
                                if ($null -ne $item) { $streamItems.Add($item) }
                            }
                        }
                    } else {
                        $job = Invoke-Command -Session $session -ScriptBlock $runnerSb -ArgumentList $invokeArgs -AsJob -ErrorAction Stop

                        while ($job.State -eq 'Running' -or $job.State -eq 'NotStarted') {
                            for ($pollTick = 0; $pollTick -lt 5; $pollTick++) {
                                Start-Sleep -Milliseconds 50
                                if ($SharedState.CancelRequested) { break }
                            }
                            if ($SharedState.CancelRequested) {
                                $stepWasStopped = $true
                                try { Stop-Job -Job $job -ErrorAction SilentlyContinue } catch {}
                                break
                            }
                            $received = @(Receive-Job -Job $job -ErrorAction SilentlyContinue)
                            foreach ($item in $received) {
                                $streamItems.Add($item)
                                if ($item.PSObject.Properties['IsLiveProgress'] -and $item.IsLiveProgress -eq $true) {
                                    $lastLiveLine = $item.Line
                                }
                            }
                            $currentSec = [int]$sw.Elapsed.TotalSeconds
                            if ($currentSec -ne $lastSecTick) {
                                $lastSecTick = $currentSec
                                $currentDur = ("{0:N1}s" -f $sw.Elapsed.TotalSeconds)
                                $currentDetails = if ($lastLiveLine) { $lastLiveLine } else { "Executing step $($step.Order) on $Computer... ($currentDur)" }
                                Send-RowUpdate -Step $stepDesc -Status "Running..." -Details $currentDetails -LiveDuration $currentDur
                            }
                            if ($currentSec - $lastHeartbeat -ge 10) {
                                $lastHeartbeat = $currentSec
                                Send-Log "Target '$Computer': Step $($step.Order) heartbeat - running for $($currentSec)s..."
                            }
                        }

                        if (-not $stepWasStopped -and -not $SharedState.CancelRequested -and $job.State -ne 'Stopped') {
                            $finalReceived = @(Receive-Job -Job $job -Wait -ErrorAction Stop)
                            foreach ($item in $finalReceived) { $streamItems.Add($item) }
                        } else {
                            $stepWasStopped = $true
                        }
                    }

                    if ($SharedState.CancelRequested -or $stepWasStopped) {
                        $sw.Stop()
                        $stepDurStr = ("{0:N1}s" -f $sw.Elapsed.TotalSeconds)
                        $compStopped = $true
                        $stopMsg = "Deployment stopped by user during step $($step.Order) ($($step.Name)) after $stepDurStr."
                        Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Stopped" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $stopMsg
                        for ($skipIdx = $i + 1; $skipIdx -lt $Steps.Count; $skipIdx++) {
                            $skipStep = $Steps[$skipIdx]
                            Send-StepHistory -StepIndex $skipIdx -StepOrder $skipStep.Order -StepName $skipStep.Name -StepType $skipStep.Type -Status "Skipped" -Duration "0.0s" -Seconds 0.0 -Details "Skipped — deployment stopped by user."
                        }
                        Send-RowUpdate -Step $stepDesc -Status "Stopped" -Details $stopMsg -AddSeconds $sw.Elapsed.TotalSeconds
                        Send-Log "Target '$Computer': Step $($step.Order) stopped by user after $stepDurStr." "WARN"
                        break
                    }

                    $sw.Stop()
                    $stepDurStr = ("{0:N1}s" -f $sw.Elapsed.TotalSeconds)

                    $res = ($streamItems | Where-Object { $_.PSObject.Properties['IsLiveProgress'] -and $_.IsLiveProgress -eq $false } | Select-Object -Last 1)
                    if ($res -and $res.Success) {
                        $successMsg = if ($res.Message) { $res.Message } else { "Step $($step.Order) completed successfully." }
                        Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Success" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $successMsg
                        Send-RowUpdate -Step $stepDesc -Status "Running..." -Details $successMsg -AddSeconds $sw.Elapsed.TotalSeconds
                        Send-Log "Target '$Computer': Step $($step.Order) complete. Status=Success, Duration=$stepDurStr, Details=$successMsg"
                    } else {
                        $reason = if ($res -and -not [string]::IsNullOrWhiteSpace($res.Message)) {
                            $res.Message
                        } elseif ($res -and $res.ExitCode -ne $null) {
                            "Script exited with non-zero code ($($res.ExitCode))."
                        } else {
                            "Execution stopped unexpectedly without returning diagnostic text."
                        }
                        Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Failed" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $reason
                        Send-RowUpdate -Step $stepDesc -Status "Failed" -Details $reason -AddSeconds $sw.Elapsed.TotalSeconds -FailedStepIndex $i
                        Send-Log "Target '$Computer': Step $($step.Order) complete. Status=Failed, Duration=$stepDurStr, Details=$reason" "ERROR"
                        $compFailed = $true
                        if (-not $ContinueOnError) {
                            for ($skipIdx = $i + 1; $skipIdx -lt $Steps.Count; $skipIdx++) {
                                $skipStep = $Steps[$skipIdx]
                                Send-StepHistory -StepIndex $skipIdx -StepOrder $skipStep.Order -StepName $skipStep.Name -StepType $skipStep.Type -Status "Skipped" -Duration "0.0s" -Seconds 0.0 -Details "Skipped — prior step $($step.Order) failed."
                            }
                            break
                        }
                    }
                }
                catch {
                    $sw.Stop()
                    $stepDurStr = ("{0:N1}s" -f $sw.Elapsed.TotalSeconds)
                    if ($SharedState.CancelRequested) {
                        $compStopped = $true
                        $stopMsg = "Deployment stopped by user during step $($step.Order) ($($step.Name))."
                        Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Stopped" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $stopMsg
                        Send-RowUpdate -Step $stepDesc -Status "Stopped" -Details $stopMsg -AddSeconds $sw.Elapsed.TotalSeconds
                        break
                    }
                    $errText = $_.Exception.Message
                    $hint = Get-WinRMHint -Message $errText -CredKind $CredInfo.CredKind
                    $failMsg = "REMOTE FAULT: $hint$errText"
                    Send-Log "Target '$Computer': Step $($step.Order) exception: $failMsg" "ERROR"
                    Send-StepHistory -StepIndex $i -StepOrder $step.Order -StepName $step.Name -StepType $step.Type -Status "Failed" -Duration $stepDurStr -Seconds $sw.Elapsed.TotalSeconds -Details $failMsg
                    Send-RowUpdate -Step $stepDesc -Status "Failed" -Details $failMsg -AddSeconds $sw.Elapsed.TotalSeconds -FailedStepIndex $i
                    $compFailed = $true
                    if (-not $ContinueOnError) {
                        for ($skipIdx = $i + 1; $skipIdx -lt $Steps.Count; $skipIdx++) {
                            $skipStep = $Steps[$skipIdx]
                            Send-StepHistory -StepIndex $skipIdx -StepOrder $skipStep.Order -StepName $skipStep.Name -StepType $skipStep.Type -Status "Skipped" -Duration "0.0s" -Seconds 0.0 -Details "Skipped — prior step $($step.Order) failed."
                        }
                        break
                    }
                }
                finally {
                    if ($null -ne $localPs) {
                        try { $localPs.Dispose() } catch {}
                    }
                    if ($null -ne $job -and $job -is [System.Management.Automation.Job]) {
                        try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch {}
                    }
                }
            }

            if ($compStopped) {
                Send-Log "Target '$Computer': Deployment stopped by user." "WARN"
                Send-TargetDone "Stopped"
            } elseif ($compFailed) {
                Send-Log "Target '$Computer': Deployment finished with failure." "ERROR"
                Send-TargetDone "Failed"
            } else {
                Send-Log "Target '$Computer': Deployment finished with success."
                Send-TargetDone "Success"
            }
        }
        finally {
            if ($session) {
                Remove-PSSession $session -ErrorAction SilentlyContinue
            }
        }
    }

    try {
        $stepRunnerStr = $stepRunner.ToString()
        foreach ($computer in $TargetComputers) {
            $tCtx = $targetContextMap[$computer]
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript($workerScript).
                AddArgument($computer).
                AddArgument($stepsData).
                AddArgument($StartStepIndex).
                AddArgument($continueOnError).
                AddArgument($remoteStagingBase).
                AddArgument($tCtx.CredInfo).
                AddArgument($stepRunnerStr).
                AddArgument($sharedState).
                AddArgument($eventQueue)

            $asyncHandle = $ps.BeginInvoke()
            $workerHandles.Add([PSCustomObject]@{
                Computer = $computer
                PS       = $ps
                Handle   = $asyncHandle
            })
        }

        if (-not $script:ActiveDeployments) {
            $script:ActiveDeployments = [System.Collections.Generic.List[psobject]]::new()
        }

        $batchObj = [PSCustomObject]@{
            BatchId          = $deploymentId
            DeploymentId     = $deploymentId
            DeployRun        = $deployRun
            StartedAt        = [datetime]::Now
            PackageName      = $pkgName
            TargetComputers  = @($TargetComputers)
            StepsCount       = $steps.Count
            MaxConcurrency   = $maxConcurrency
            TargetContextMap = $targetContextMap
            EventQueue       = $eventQueue
            SharedState      = $sharedState
            Pool             = $pool
            WorkerHandles    = $workerHandles
            TotalOk          = 0
            TotalFail        = 0
            TotalStopped     = 0
        }
        $script:ActiveDeployments.Add($batchObj)
        $script:IsDeploymentRunning = $true
        $script:CancelDeploymentRequested = $false

        if ($dgDeployPackages) {
            $dgDeployPackages.SelectedItem = $deployRun
            $dgDeployPackages.Items.Refresh()
        }
        Invoke-RefreshResultsFilter
        Save-PersistentStatusState

        if ($btnStopDeploy) {
            $btnStopDeploy.Content   = "⏹ Stop Deployment"
            $btnStopDeploy.IsEnabled = $true
        }
        Update-DeploymentRunningBadge
        Ensure-DeploymentMonitorTimer
        $lblStatus.Text = "Started deployment of '$pkgName' to $($TargetComputers.Count) host(s) ($($script:ActiveDeployments.Count) active package deployment(s))."
    }
    catch {
        Write-DiagnosticLog "Failed to launch deployment batch for '$pkgName': $($_.Exception.Message)" "ERROR"
        if ($pool) {
            try { $pool.Close(); $pool.Dispose() } catch {}
        }
    }
}

function Update-DeploymentRunningBadge {
    if (-not $lblDeployRunningBadge) { return }
    $activeCount = if ($script:ActiveDeployments) { $script:ActiveDeployments.Count } else { 0 }
    if ($activeCount -gt 0) {
        $pkgNames = @($script:ActiveDeployments | ForEach-Object { $_.PackageName } | Select-Object -Unique)
        $lblDeployRunningBadge.Text = "⚡ Running ($activeCount): $($pkgNames -join ', ')"
    } else {
        $lblDeployRunningBadge.Text = ""
    }
}

function Process-ActiveDeploymentsTick {
    if (-not $script:ActiveDeployments -or $script:ActiveDeployments.Count -eq 0) {
        $script:IsDeploymentRunning = $false
        if ($script:DeployMonitorTimer) { $script:DeployMonitorTimer.Stop() }
        if ($btnStopDeploy) {
            $btnStopDeploy.IsEnabled = $false
            $btnStopDeploy.Content   = "⏹ Stop Deployment"
        }
        Update-DeploymentRunningBadge
        return
    }

    $needsGridRefresh = $false
    $completedBatches = [System.Collections.Generic.List[psobject]]::new()

    foreach ($batch in @($script:ActiveDeployments)) {
        if ($script:CancelDeploymentRequested -and -not $batch.SharedState.CancelRequested) {
            $batch.SharedState.CancelRequested = $true
        }

        $ev = $null
        while ($batch.EventQueue.TryDequeue([ref]$ev)) {
            try {
                $tCtx = $batch.TargetContextMap[$ev.Computer]
                if (-not $tCtx) { continue }
                $row = $tCtx.Row

                switch ($ev.EventType) {
                    'Log' {
                        Write-DiagnosticLog "[$($batch.PackageName)] $($ev.Message)" $ev.Level
                    }
                    'RowUpdate' {
                        if (-not [string]::IsNullOrWhiteSpace($ev.LiveDuration)) {
                            $row.Duration = $ev.LiveDuration
                        }
                        Update-ComputerRow -Row $row -Step $ev.Step -Status $ev.Status -Details $ev.Details -AddSeconds $ev.AddSeconds -FailedStepIndex $ev.FailedStepIndex
                        $needsGridRefresh = $true
                    }
                    'StepHistory' {
                        Set-StepHistoryEntry -Row $row -StepIndex $ev.StepIndex -StepOrder $ev.StepOrder -StepName $ev.StepName -StepType $ev.StepType -Status $ev.Status -Duration $ev.Duration -Seconds $ev.Seconds -Details $ev.Details
                    }
                    'TargetDone' {
                        if (-not $tCtx.Done) {
                            $tCtx.Done = $true
                            if ($ev.Outcome -eq 'Stopped') {
                                $batch.TotalStopped++
                            } elseif ($ev.Outcome -eq 'Failed') {
                                $batch.TotalFail++
                            } elseif ($ev.Outcome -eq 'Success') {
                                $batch.TotalOk++
                                $lastStepHist = if ($row.StepHistory -and $row.StepHistory.Count -gt 0) { $row.StepHistory[$row.StepHistory.Count - 1] } else { $null }
                                $summaryPreview = if ($lastStepHist -and -not [string]::IsNullOrWhiteSpace($lastStepHist.Details)) {
                                    Format-StepDetailsPreview -Text $lastStepHist.Details -MaxLength 160
                                } else {
                                    "All $($batch.StepsCount) step(s) completed successfully."
                                }
                                Update-ComputerRow -Row $row -Step "All Steps Complete" -Status "Success" -Details $summaryPreview
                            }
                        }
                        Save-PersistentStatusState
                        $needsGridRefresh = $true
                    }
                }
            } catch {
                Write-DiagnosticLog "Event processing error for '$($ev.Computer)': $($_.Exception.Message)" "WARN"
            }
        }

        # Reconcile target counts directly from TargetContextMap rows to guarantee accuracy
        $rowOk = 0
        $rowFail = 0
        $rowStop = 0
        foreach ($ctxVal in $batch.TargetContextMap.Values) {
            $rStat = [string]$ctxVal.Row.Status
            if ($rStat -eq 'Success') {
                $rowOk++
            } elseif ($rStat -eq 'Failed' -or $rStat -like '*Fail*' -or $rStat -eq 'Offline') {
                $rowFail++
            } elseif ($rStat -in @('Stopped', 'Cancelled')) {
                $rowStop++
            }
        }
        if ($rowOk -gt $batch.TotalOk)     { $batch.TotalOk = $rowOk }
        if ($rowFail -gt $batch.TotalFail) { $batch.TotalFail = $rowFail }
        if ($rowStop -gt $batch.TotalStopped) { $batch.TotalStopped = $rowStop }

        # Update live deployment run progress in DEPLOYMENT table
        if ($batch.DeployRun) {
            $doneCnt = $batch.TotalOk + $batch.TotalFail + $batch.TotalStopped
            $totCnt  = [int]@($batch.TargetComputers).Count
            $elapsedSec = [Math]::Max(0.0, ([datetime]::Now - $batch.StartedAt).TotalSeconds)
            $batch.DeployRun.CompletedCount  = $doneCnt
            $batch.DeployRun.SuccessCount    = $batch.TotalOk
            $batch.DeployRun.FailedCount     = $batch.TotalFail
            $batch.DeployRun.StoppedCount    = $batch.TotalStopped
            $batch.DeployRun.DurationSeconds = [Math]::Round($elapsedSec, 1)
            $batch.DeployRun.Duration        = ("{0:N1}s" -f $elapsedSec)
            $batch.DeployRun.TargetSummary   = "$doneCnt/$totCnt ($($batch.TotalOk) OK, $($batch.TotalFail) Fail)"
        }

        $runningWorkers = @($batch.WorkerHandles | Where-Object { -not $_.Handle.IsCompleted })
        if ($runningWorkers.Count -eq 0 -and $batch.EventQueue.IsEmpty) {
            $completedBatches.Add($batch)
        }
    }

    foreach ($doneBatch in $completedBatches) {
        foreach ($w in $doneBatch.WorkerHandles) {
            try {
                if ($w.Handle -and $w.Handle.IsCompleted) {
                    [void]$w.PS.EndInvoke($w.Handle)
                }
            } catch {
                $wCtx = $doneBatch.TargetContextMap[$w.Computer]
                if ($wCtx -and $wCtx.Row -and $wCtx.Row.Status -notin @('Success', 'Failed', 'Stopped')) {
                    Update-ComputerRow -Row $wCtx.Row -Status "Failed" -Details "Worker unhandled exception: $($_.Exception.Message)"
                }
            }
            try { $w.PS.Dispose() } catch {}
        }
        if ($doneBatch.Pool) {
            try { $doneBatch.Pool.Close() } catch {}
            try { $doneBatch.Pool.Dispose() } catch {}
        }
        [void]$script:ActiveDeployments.Remove($doneBatch)

        # Final authoritative recount across all target rows in the finished batch
        $finalOk   = 0
        $finalFail = 0
        $finalStop = 0
        foreach ($ctxVal in $doneBatch.TargetContextMap.Values) {
            $r = $ctxVal.Row
            if (-not $r) { continue }
            if ($r.Status -eq 'Success') {
                $finalOk++
            } elseif ($r.Status -in @('Stopped', 'Cancelled')) {
                $finalStop++
            } else {
                if ($r.Status -ne 'Failed') {
                    Update-ComputerRow -Row $r -Status "Failed" -Details (if ($r.Details) { $r.Details } else { "Deployment worker terminated before completion." })
                }
                $finalFail++
            }
        }
        $doneBatch.TotalOk      = $finalOk
        $doneBatch.TotalFail    = $finalFail
        $doneBatch.TotalStopped = $finalStop

        if ($doneBatch.DeployRun) {
            $totCnt = [int]@($doneBatch.TargetComputers).Count
            $doneCnt = $doneBatch.TotalOk + $doneBatch.TotalFail + $doneBatch.TotalStopped
            $elapsedSec = [Math]::Max(0.0, ([datetime]::Now - $doneBatch.StartedAt).TotalSeconds)
            $doneBatch.DeployRun.CompletedCount  = $doneCnt
            $doneBatch.DeployRun.SuccessCount    = $doneBatch.TotalOk
            $doneBatch.DeployRun.FailedCount     = $doneBatch.TotalFail
            $doneBatch.DeployRun.StoppedCount    = $doneBatch.TotalStopped
            $doneBatch.DeployRun.EndTime         = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $doneBatch.DeployRun.DurationSeconds = [Math]::Round($elapsedSec, 1)
            $doneBatch.DeployRun.Duration        = ("{0:N1}s" -f $elapsedSec)
            $doneBatch.DeployRun.TargetSummary   = "$doneCnt/$totCnt ($($doneBatch.TotalOk) OK, $($doneBatch.TotalFail) Fail)"
            if ($doneBatch.SharedState.CancelRequested -or ($doneBatch.TotalStopped -gt 0 -and $doneBatch.TotalFail -eq 0)) {
                $doneBatch.DeployRun.Status = "Stopped"
            } elseif ($doneBatch.TotalFail -gt 0) {
                $doneBatch.DeployRun.Status = "Failed"
            } elseif ($doneBatch.TotalOk -gt 0 -and $doneBatch.TotalOk -eq $totCnt) {
                $doneBatch.DeployRun.Status = "Success"
            } else {
                $doneBatch.DeployRun.Status = "Failed"
            }
        }
        Save-PersistentStatusState
        $needsGridRefresh = $true

        if ($doneBatch.SharedState.CancelRequested) {
            $msg = "Package '$($doneBatch.PackageName)' stopped: $($doneBatch.TotalOk) succeeded, $($doneBatch.TotalFail) failed, $($doneBatch.TotalStopped) stopped across $($doneBatch.TargetComputers.Count) host(s)."
            $lblStatus.Text = $msg
            Write-DiagnosticLog $msg "WARN"
        } else {
            $msg = "Package '$($doneBatch.PackageName)' finished: $($doneBatch.TotalOk) succeeded, $($doneBatch.TotalFail) failed across $($doneBatch.TargetComputers.Count) host(s)."
            $lblStatus.Text = $msg
            Write-DiagnosticLog $msg
        }
    }

    if ($dgDeployPackages) {
        try { $dgDeployPackages.Items.Refresh() } catch {}
    }
    if ($needsGridRefresh -and $dgResults) {
        Invoke-RefreshResultsFilter
    }

    Update-DeploymentRunningBadge

    if ($script:ActiveDeployments.Count -gt 0) {
        $totalTargets = 0
        $totalDone    = 0
        $pkgSummaries = @()
        foreach ($b in $script:ActiveDeployments) {
            $bDone = $b.TotalOk + $b.TotalFail + $b.TotalStopped
            $totalTargets += $b.TargetComputers.Count
            $totalDone    += $bDone
            $pkgSummaries += "$($b.PackageName) [$bDone/$($b.TargetComputers.Count)]"
        }
        if (-not $script:CancelDeploymentRequested) {
            $lblStatus.Text = "Deploying ($($script:ActiveDeployments.Count) package batch(es) active): $($pkgSummaries -join ' | ')..."
        }
    } else {
        $script:IsDeploymentRunning = $false
        $script:CancelDeploymentRequested = $false
        if ($script:DeployMonitorTimer) { $script:DeployMonitorTimer.Stop() }
        if ($btnStopDeploy) {
            $btnStopDeploy.IsEnabled = $false
            $btnStopDeploy.Content   = "⏹ Stop Deployment"
        }
    }
}

function Ensure-DeploymentMonitorTimer {
    if (-not $script:DeployMonitorTimer) {
        $script:DeployMonitorTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:DeployMonitorTimer.Interval = [TimeSpan]::FromMilliseconds(50)
        $script:DeployMonitorTimer.Add_Tick({
            Process-ActiveDeploymentsTick
        })
    }
    if (-not $script:DeployMonitorTimer.IsEnabled) {
        $script:DeployMonitorTimer.Start()
    }
}

function Get-ValidatedSelectedTargetComputers {
    $useCurrentCred = [bool]$script:AppSettings.UseCurrentCred
    $hasSavedCred = (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Username)) -and ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0)
    if (-not $useCurrentCred -and -not $hasSavedCred) {
        $ans = [System.Windows.MessageBox]::Show("Admin credentials are not configured.`n`nOpen Settings dialog now to configure credentials or select current logon?", "Credentials Required", "YesNo", "Warning")
        if ($ans -eq 'Yes') {
            Show-SettingsDialog
            $useCurrentCred = [bool]$script:AppSettings.UseCurrentCred
            $hasSavedCred = (-not [string]::IsNullOrWhiteSpace($script:AppSettings.Username)) -and ($null -ne $script:AppSettings.SecurePassword -and $script:AppSettings.SecurePassword.Length -gt 0)
        }
        if (-not $useCurrentCred -and -not $hasSavedCred) {
            return @()
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($txtSingleComp.Text)) {
        $rawHosts = $txtSingleComp.Text -split '[,;\r\n\s]+' | Where-Object { $_ }
        Add-TargetComputers -Hostnames $rawHosts
        $txtSingleComp.Text = ""
    }

    $selectedTargets = if (Test-TargetFilterActive) {
        @($script:TargetsCollection | Where-Object { [bool]$_.Selected -and (Test-TargetItemFilter -Item $_) } | ForEach-Object { $_.ComputerName })
    } else {
        @($script:TargetsCollection | Where-Object { [bool]$_.Selected } | ForEach-Object { $_.ComputerName })
    }

    if ($selectedTargets.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No target systems are selected for deployment.`n`nAdd computers to the Target Computers list and ensure their 'Deploy' checkbox is checked.", "Validation Error", "OK", "Warning")
        return @()
    }
    return $selectedTargets
}

# ------------------------------------------
# Stop & Start Deployment Trigger Handlers
# ------------------------------------------
if ($btnStopDeploy) {
    $btnStopDeploy.Add_Click({
        if (-not $script:ActiveDeployments -or $script:ActiveDeployments.Count -eq 0) { return }
        $script:CancelDeploymentRequested = $true
        foreach ($batch in @($script:ActiveDeployments)) {
            if ($batch.SharedState) {
                $batch.SharedState.CancelRequested = $true
            }
        }
        $btnStopDeploy.IsEnabled = $false
        $btnStopDeploy.Content = "⏳ Stopping..."
        $lblStatus.Text = "Stopping all active deployments... cancelling remote operation(s)..."
        Write-DiagnosticLog "User clicked Stop Deployment. Cancelling $($script:ActiveDeployments.Count) active deployment batch(es)..." "WARN"
    })
}

if ($btnDeployActiveNow) {
    $btnDeployActiveNow.Add_Click({
        if ($script:StepsCollection.Count -eq 0) {
            [System.Windows.MessageBox]::Show("The active package has no steps to deploy. Select a package or click '📦 Edit Package Steps...' to add steps.", "Validation Error", "OK", "Warning")
            return
        }
        $selectedTargets = @(Get-ValidatedSelectedTargetComputers)
        if ($selectedTargets.Count -eq 0) { return }
        $activePkgName = if ($txtPkgName -and -not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) { $txtPkgName.Text.Trim() } else { "(Untitled Package)" }
        Invoke-DeploymentForTargets -TargetComputers $selectedTargets -StartStepIndex 0 -PackageName $activePkgName -PackageSteps @($script:StepsCollection)
    })
}

if ($btnDeployCheckedPkgs) {
    $btnDeployCheckedPkgs.Add_Click({
        $checkedPkgRows = @($script:DeployPackagesCollection | Where-Object { [bool]$_.Selected -and $_.PackageRef })
        if ($checkedPkgRows.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No packages are checked in the Multi-Package Queue.`n`nCheck one or more packages in the 'Deploy' column (or use '🚀 Deploy Active Package').", "No Packages Checked", "OK", "Information")
            return
        }
        $selectedTargets = @(Get-ValidatedSelectedTargetComputers)
        if ($selectedTargets.Count -eq 0) { return }

        foreach ($pkgRow in $checkedPkgRows) {
            $pkgObj = $pkgRow.PackageRef
            $pkgSteps = @($pkgObj.Steps)
            if ($pkgSteps.Count -eq 0) { continue }
            Invoke-DeploymentForTargets -TargetComputers $selectedTargets -StartStepIndex 0 -PackageName $pkgObj.Name -PackageSteps $pkgSteps
        }
    })
}

if ($btnStart) {
    $btnStart.Add_Click({
        if ($script:StepsCollection.Count -eq 0) {
            [System.Windows.MessageBox]::Show("The selected package has no steps to deploy. Double-click or right-click a package in Package Library to add or edit steps.", "Validation Error", "OK", "Warning")
            return
        }
        $selectedTargets = @(Get-ValidatedSelectedTargetComputers)
        if ($selectedTargets.Count -eq 0) { return }
        $activePkgName = if ($txtPkgName -and -not [string]::IsNullOrWhiteSpace($txtPkgName.Text)) { $txtPkgName.Text.Trim() } else { "(Untitled Package)" }
        Invoke-DeploymentForTargets -TargetComputers $selectedTargets -StartStepIndex 0 -PackageName $activePkgName -PackageSteps @($script:StepsCollection)
    })
}

# Apply lightweight UI layout state immediately before rendering; defer disk/network hydration to ContentRendered for instant startup
Load-UiLayoutState
Apply-MainWindowLayoutState
Update-ActivePackageBanner

$script:StartupHydrationCompleted = $false
$window.Add_ContentRendered({
    if ($script:StartupHydrationCompleted) { return }
    $script:StartupHydrationCompleted = $true
    if ($lblStatus) {
        $lblStatus.Text = "Loading package library and computer inventory..."
        $lblStatus.Foreground = "#38BDF8"
    }
    $null = $window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{
        try {
            Load-PackageLibrary
            Update-ActivePackageBanner
            Load-AdSyncConfig
            Update-AdSyncStatusBadge
        } catch {}
        $null = $window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::ContextIdle, [Action]{
            try {
                Load-ComputerInventory
                if ($script:InventoryNeedsAdResync -and $script:AdSyncConfig -and $script:AdSyncConfig.Containers -and @($script:AdSyncConfig.Containers).Count -gt 0) {
                    $script:InventoryNeedsAdResync = $false
                    Invoke-AdSync -Silent
                }
                Load-PersistentStatusState
                Update-AdAutoSyncTimer
                Update-AutoProbeTimer
            } catch {}
        })
    })
})

$window.Add_Closing({
    $script:AppIsClosing = $true
    if ($script:PkgStepsModalWindow) {
        try { $script:PkgStepsModalWindow.Close() } catch {}
    }
    Save-UiLayoutState
})

$window.Add_Closed({
    try {
        if ($script:AdAutoSyncTimer) { $script:AdAutoSyncTimer.Stop() }
        if ($script:AutoProbeTimer) { $script:AutoProbeTimer.Stop() }
        if ($script:DeployMonitorTimer) { $script:DeployMonitorTimer.Stop() }
        if ($script:ActiveDeployments) {
            foreach ($b in $script:ActiveDeployments) {
                if ($b.SharedState) { $b.SharedState.CancelRequested = $true }
                if ($b.Pool) { try { $b.Pool.Close(); $b.Pool.Dispose() } catch {} }
            }
            $script:ActiveDeployments.Clear()
        }
        if ($script:ProbeDispatcherTimer) { $script:ProbeDispatcherTimer.Stop() }
        if ($script:PendingProbeQueue) { $script:PendingProbeQueue.Clear() }
        if ($script:PendingProbeKeys) { $script:PendingProbeKeys.Clear() }
        if ($script:ActiveProbeJobs) {
            foreach ($j in $script:ActiveProbeJobs) {
                if ($j.PowerShell) { try { $j.PowerShell.Dispose() } catch {} }
            }
            $script:ActiveProbeJobs.Clear()
        }
        if ($script:ProbeRunspacePool) {
            try { $script:ProbeRunspacePool.Close(); $script:ProbeRunspacePool.Dispose() } catch {}
        }
    } catch {}
    Save-ComputerInventory
    Save-AdSyncConfig
    Save-UiLayoutState
    Save-PersistentStatusState
})

$window.ShowDialog() | Out-Null
